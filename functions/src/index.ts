import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─── helpers ──────────────────────────────────────────────────────────────────

/**
 * Fetch all enabled auto_notifications for a merchant matching a given trigger.
 */
async function getEnabledNotifications(
  merchantId: string,
  trigger: string
): Promise<admin.firestore.QueryDocumentSnapshot[]> {
  const snap = await db
    .collection("merchants")
    .doc(merchantId)
    .collection("auto_notifications")
    .where("is_enabled", "==", true)
    .where("trigger", "==", trigger)
    .get();
  return snap.docs;
}

/**
 * Return all follower UIDs for a merchant (collection-group query).
 */
async function getFollowerIds(merchantId: string): Promise<string[]> {
  const snap = await db
    .collectionGroup("followed_merchants")
    .where("merchant_id", "==", merchantId)
    .get();
  return snap.docs
    .map((d) => d.ref.parent.parent?.id ?? "")
    .filter((id) => id !== "");
}

// ─── Segment helpers ──────────────────────────────────────────────────────────

/**
 * CANONICAL segment model — passage-based, single source of truth.
 *
 * Mirrors Flutter's `FirestoreClientLoyaltyRepository._computeSegment`
 * (`lib/feature/loyalty/infrastructure/firestore_client_loyalty_repository.dart`):
 *   - daysSinceLastVisit > 60  → 'inactif'
 *   - validatedPassages >= 10  → 'vip'
 *   - validatedPassages >= 3   → 'habitue'
 *   - otherwise                → 'nouveau'
 *
 * A client with NO loyalty_clients doc defaults to 'nouveau' (new follower,
 * no visits yet). 'abonne' is retired from notification targeting.
 *
 * Exported for unit testing; intentionally pure (no Firebase calls).
 */
export function computeSegment(
  validatedPassages: number,
  daysSinceLastVisit: number
): string {
  if (daysSinceLastVisit > 60) return "inactif";
  if (validatedPassages >= 10) return "vip";
  if (validatedPassages >= 3) return "habitue";
  return "nouveau";
}

/**
 * Returns the passage-based segment key for a client at a specific merchant.
 * Reads `merchants/{merchantId}/loyalty_clients/{clientId}`.
 * Falls back to 'nouveau' when the document is missing (no visits recorded yet).
 */
async function getClientSegment(
  clientId: string,
  merchantId: string
): Promise<string> {
  try {
    const doc = await db
      .collection("merchants")
      .doc(merchantId)
      .collection("loyalty_clients")
      .doc(clientId)
      .get();
    if (!doc.exists) return "nouveau";
    const data = doc.data() ?? {};
    const validatedPassages: number =
      typeof data.validated_passages === "number" ? data.validated_passages : 0;
    const updatedAt: FirebaseFirestore.Timestamp | undefined = data.updated_at;
    // No updated_at = client has never visited → treat as very stale (999 days).
    const daysSinceLastVisit = updatedAt
      ? (Date.now() - updatedAt.toDate().getTime()) / (1000 * 60 * 60 * 24)
      : 999;
    return computeSegment(validatedPassages, daysSinceLastVisit);
  } catch (e) {
    functions.logger.warn("getClientSegment error", {
      clientId,
      merchantId,
      error: e,
    });
    return "nouveau";
  }
}

/**
 * Returns true if the notifDoc's audience/segment config allows sending to
 * this client. Centralises the segment-filter logic so it can be reused in
 * both dispatchTrigger and dailyScheduledTriggers.
 *
 * Rules:
 *   - audience == "Tous mes clients" → always true
 *   - audience == "Certains clients" with empty segments → true (broadcast)
 *   - audience == "Certains clients" with segments → true iff client's segment
 *     is in the (normalised) list
 *
 * Backward compatibility: stored "abonne" segments are remapped to "nouveau"
 * so that auto-notifications created before the model change still fire.
 * The passage-based model never produces "abonne", so "abonne" → "nouveau"
 * is the closest semantic equivalent (active follower with low engagement).
 */
async function shouldSendToClient(
  notifDoc: admin.firestore.QueryDocumentSnapshot,
  clientId: string,
  merchantId: string
): Promise<boolean> {
  const data = notifDoc.data();
  const audience: string = data.audience ?? "Tous mes clients";
  const rawSegments: string[] = data.target_segments ?? [];

  if (audience !== "Certains clients" || rawSegments.length === 0) return true;

  // Normalise legacy "abonne" → "nouveau" for backward compat.
  const segments = rawSegments.map((s) => (s === "abonne" ? "nouveau" : s));

  const clientSegment = await getClientSegment(clientId, merchantId);
  return segments.includes(clientSegment);
}

/**
 * Send an in-app notification document → triggers onNotificationCreated push.
 * Also increments sent_count + last_sent_at on the auto_notification document.
 */
async function fireAutoNotification(
  notifDoc: admin.firestore.QueryDocumentSnapshot,
  merchantId: string,
  clientId: string
): Promise<void> {
  const data = notifDoc.data();
  const merchantSnap = await db.collection("merchants").doc(merchantId).get();
  const merchantName: string = merchantSnap.data()?.name ?? "Votre commerce";

  await db
    .collection("users")
    .doc(clientId)
    .collection("notifications")
    .add({
      client_id: clientId,
      merchant_id: merchantId,
      merchant_name: merchantName,
      // 'auto' type — tap routes to notifications tab (no promotion_id for deep-link).
      // merchant_id IS included so onNotificationCreated forwards it in FCM data,
      // allowing future routing enhancements without schema changes.
      type: "auto",
      title: data.title ?? merchantName,
      body: data.text ?? "",
      is_read: false,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

  // Increment delivery stats on the auto_notification doc (best-effort).
  notifDoc.ref
    .set(
      {
        sent_count: admin.firestore.FieldValue.increment(1),
        last_sent_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    )
    .catch((e) =>
      functions.logger.warn("Could not update sent_count", { error: e })
    );
}

/**
 * Trigger notifications for all followers (or a single client) matching a trigger.
 * If `targetClientId` is given, only notify that one client (event-based triggers).
 * When audience is "Certains clients" and `target_segments` is non-empty, only
 * followers whose CRM segment matches are notified.
 */
async function dispatchTrigger(
  merchantId: string,
  trigger: string,
  targetClientId?: string
): Promise<void> {
  const notifDocs = await getEnabledNotifications(merchantId, trigger);
  if (notifDocs.length === 0) return;

  const clientIds: string[] = targetClientId
    ? [targetClientId]
    : await getFollowerIds(merchantId);

  for (const notifDoc of notifDocs) {
    for (const clientId of clientIds) {
      // Segment check: passage-based via shouldSendToClient.
      // "Certains clients" with empty segments = broadcast to all (same as Tous).
      const allowed = await shouldSendToClient(notifDoc, clientId, merchantId);
      if (!allowed) continue;

      await fireAutoNotification(notifDoc, merchantId, clientId).catch((e) =>
        functions.logger.error("fireAutoNotification error", { clientId, error: e })
      );
    }
  }
}

// ─── 1. onNotificationCreated — FCM push ─────────────────────────────────────

/**
 * Triggered when a new ClientNotification document is created at
 * users/{userId}/notifications/{notificationId}.
 * Reads FCM token and sends a push notification.
 */
export const onNotificationCreated = functions
  .region("europe-west1")
  .firestore.document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const data = snap.data();
    if (!data) return null;

    const tokenDoc = await db
      .collection("users")
      .doc(userId)
      .collection("push_tokens")
      .doc("device")
      .get();

    if (!tokenDoc.exists) return null;
    const fcmToken: string | undefined = tokenDoc.data()?.fcm_token;
    if (!fcmToken) return null;

    const title: string = data.title ?? "Yuztoo";
    const body: string = data.body ?? "";
    const notificationId: string = snap.id;
    const promotionId: string | undefined = data.promotion_id;
    const merchantId: string | undefined = data.merchant_id;

    // Count unread notifications for this user to use as the iOS badge count.
    // The new notification doc is already created (is_read: false by default),
    // so this returns the true unread count including the new one.
    let badgeCount = 1;
    try {
      const unreadSnap = await db
        .collection("users")
        .doc(userId)
        .collection("notifications")
        .where("is_read", "==", false)
        .count()
        .get();
      badgeCount = unreadSnap.data().count;
    } catch (_) {
      // count() requires Firestore Blaze plan — fall back to 1 if unavailable.
      badgeCount = 1;
    }

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: { title, body },
      data: {
        notification_id: notificationId,
        type: data.type ?? "auto",
        ...(promotionId ? { promotion_id: promotionId } : {}),
        ...(merchantId ? { merchant_id: merchantId } : {}),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "yuztoo_promo_v2",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        // apns-priority 10 = immediate delivery (default for alert messages but
        // must be explicit when using HTTP/2 headers directly).
        // apns-push-type 'alert' required by Apple for visible notifications.
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
        },
        payload: {
          aps: {
            sound: "default",
            badge: badgeCount,
            // content-available 1 wakes the app in background for data processing.
            // Harmless when notification block is also present (alert still shown).
            "content-available": 1,
          },
        },
      },
    };

    try {
      await messaging.send(message);
      functions.logger.info("Push sent", {
        userId,
        notificationId,
        type: data.type ?? "auto",
      });
    } catch (error: any) {
      const code: string = error?.errorInfo?.code ?? "";
      // Full set of FCM/APNs codes that signal a permanently dead token.
      // On any of these we delete the Firestore doc immediately so the
      // Flutter app's Firestore watch triggers re-registration.
      // NOTE: rate-limit errors (device-message-rate-exceeded, etc.) are NOT
      // dead-token errors — we log them but keep the token intact.
      const isDeadToken =
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token" ||
        // Returned by Firebase Admin when the APNs token has no record
        // (app deleted from device) and Admin can't map it to a valid token.
        code === "messaging/mismatched-credential";
      if (isDeadToken) {
        functions.logger.warn("Dead FCM token — deleting", { userId, code });
        await tokenDoc.ref.delete();
      } else {
        functions.logger.error("Failed to send push", {
          userId,
          notificationId,
          code,
          error: String(error),
        });
      }
    }
    return null;
  });

// ─── 2. New client followed a merchant ───────────────────────────────────────

/**
 * Fires when a client follows a merchant.
 * Triggers: "Nouveau client connecté"
 */
export const onFollowedMerchantCreated = functions
  .region("europe-west1")
  .firestore.document("users/{clientId}/followed_merchants/{merchantId}")
  .onCreate(async (snap, context) => {
    const { clientId, merchantId } = context.params;
    functions.logger.info("New follow", { clientId, merchantId });
    await dispatchTrigger(merchantId, "Nouveau client connecté", clientId);
    return null;
  });

// ─── 3. Loyalty progress updated ─────────────────────────────────────────────

/**
 * Fires when a client's loyalty progress document changes.
 * Triggers: "Passage fidélité validé", "Récompense disponible", "Récompense proche"
 */
export const onLoyaltyProgressUpdated = functions
  .region("europe-west1")
  .firestore.document(
    "merchants/{merchantId}/loyalty_clients/{clientId}"
  )
  .onWrite(async (change, context) => {
    const { merchantId, clientId } = context.params;
    if (!change.after.exists) return null; // document deleted

    const before = change.before.data() ?? {};
    const after = change.after.data() ?? {};

    const beforeValidated: number = before.validated_passages ?? 0;
    const afterValidated: number = after.validated_passages ?? 0;

    // Passage was just validated (increment).
    if (afterValidated > beforeValidated) {
      await dispatchTrigger(
        merchantId,
        "Passage fidélité validé",
        clientId
      );

      // Check if reward is now available — requires merchant loyalty config.
      const merchantSnap = await db
        .collection("merchants")
        .doc(merchantId)
        .get();
      const loyaltyConfig = merchantSnap.data()?.loyalty_program ?? {};
      const visitsRequired: number =
        loyaltyConfig.visits_required ?? loyaltyConfig.visit_count ?? 10;

      if (afterValidated >= visitsRequired) {
        // Reward unlocked.
        await dispatchTrigger(
          merchantId,
          "Récompense disponible",
          clientId
        );
      } else if (afterValidated === visitsRequired - 1) {
        // One step away from reward.
        await dispatchTrigger(
          merchantId,
          "Récompense proche",
          clientId
        );
      }
    }

    return null;
  });

// ─── 4. Promotion created or activated ───────────────────────────────────────

/**
 * Fires when a new promotion document is created.
 *
 * Does a GUARANTEED fan-out to all eligible followers — identical logic to the
 * Flutter-side NotifyFollowersOfPromotion use case (which was removed to avoid
 * the duplicate that existed when both paths ran simultaneously).
 *
 * Segment filtering:
 *   - client_type == "premium" && target_segments non-empty → only matching followers
 *   - all other promotions (gratuit, payant, or empty segments) → broadcast to all
 *   - On any read failure the segment filter is skipped and we broadcast to all
 *     rather than silently dropping a notification.
 *
 * Writes type:"promotion" with promotion_id so clients can deep-link to the promo.
 */
export const onPromotionCreated = functions
  .region("europe-west1")
  .firestore.document("merchants/{merchantId}/promotions/{promoId}")
  .onCreate(async (snap, context) => {
    const { merchantId, promoId } = context.params;
    const promoData = snap.data() ?? {};

    // Skip offline promotions (is_online: false) — merchant deliberately chose
    // not to publish yet. They will be handled by onPromotionActivated when
    // is_online flips to true (Flutter-side toggle still calls notifyFollowers).
    if (promoData.is_online === false) return null;

    const merchantSnap = await db.collection("merchants").doc(merchantId).get();
    const merchantName: string = merchantSnap.data()?.name ?? "Votre commerce";
    const promoTitle: string = promoData.title ?? "Nouvelle promotion";
    const clientType: string = promoData.client_type ?? "gratuit";
    const targetSegments: string[] = Array.isArray(promoData.target_segments)
      ? promoData.target_segments
      : [];

    // 1. Resolve all follower IDs.
    const followerIds = await getFollowerIds(merchantId);
    if (followerIds.length === 0) return null;

    // 2. Apply segment filter for premium promotions with explicit targets.
    //    gratuit and payant promotions broadcast to all followers.
    let targetIds = followerIds;
    const mustFilter = clientType === "premium" && targetSegments.length > 0;

    if (mustFilter) {
      try {
        const loyaltySnap = await db
          .collection("merchants")
          .doc(merchantId)
          .collection("loyalty_clients")
          .get();

        // Build segment map: clientId → segment.
        const segmentMap: Record<string, string> = {};
        for (const doc of loyaltySnap.docs) {
          const d = doc.data() ?? {};
          const validated: number =
            typeof d.validated_passages === "number" ? d.validated_passages : 0;
          const updatedAt: FirebaseFirestore.Timestamp | undefined = d.updated_at;
          const days = updatedAt
            ? (Date.now() - updatedAt.toDate().getTime()) / (1000 * 60 * 60 * 24)
            : 999;
          segmentMap[doc.id] = computeSegment(validated, days);
        }

        targetIds = followerIds.filter((clientId) => {
          const seg = segmentMap[clientId] ?? "nouveau";
          // Mirror promotionSegmentMatchesTarget from Dart:
          //   'soutien' target matches 'vip' or 'habitue' clients.
          for (const target of targetSegments) {
            if (target === seg) return true;
            if (
              target === "soutien" &&
              (seg === "vip" || seg === "habitue")
            ) {
              return true;
            }
          }
          return false;
        });
      } catch (e) {
        // On any read failure fall back to broadcasting to all followers.
        functions.logger.warn("onPromotionCreated: segment filter failed, broadcasting to all", {
          merchantId,
          promoId,
          error: e,
        });
        targetIds = followerIds;
      }
    }

    if (targetIds.length === 0) return null;

    // 3. Write one type:"promotion" notification per eligible follower.
    //    onNotificationCreated will forward the FCM push for each doc.
    const BATCH_SIZE = 499;
    let batch = db.batch();
    let batchCount = 0;

    for (const clientId of targetIds) {
      const notifRef = db
        .collection("users")
        .doc(clientId)
        .collection("notifications")
        .doc();

      batch.set(notifRef, {
        client_id: clientId,
        merchant_id: merchantId,
        merchant_name: merchantName,
        type: "promotion",
        title: "Nouvelle promotion",
        body: `${merchantName}\u202f: ${promoTitle}`,
        promotion_id: promoId,
        is_read: false,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      batchCount++;
      if (batchCount >= BATCH_SIZE) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    functions.logger.info("onPromotionCreated fan-out complete", {
      merchantId,
      promoId,
      totalFollowers: followerIds.length,
      notified: targetIds.length,
      segmentFiltered: mustFilter,
    });

    return null;
  });

// ─── 5b. Weekly quota reset ──────────────────────────────────────────────────

/**
 * Runs every Monday at 00:00 Europe/Paris.
 * Resets weekly_notif_sent_count to 0 on every merchant document so the
 * Rappels quota is refreshed. Without this, merchants are permanently blocked
 * after reaching the 5-notification limit.
 *
 * Uses a batched write (max 500 per batch) to be resilient to large merchant
 * counts without exceeding Firestore batch limits.
 */
export const weeklyQuotaReset = functions
  .region("europe-west1")
  .pubsub.schedule("0 0 * * 1") // Every Monday at 00:00
  .timeZone("Europe/Paris")
  .onRun(async (_context) => {
    functions.logger.info("Running weekly quota reset");

    const merchantsSnap = await db.collection("merchants").get();
    if (merchantsSnap.empty) return null;

    const BATCH_SIZE = 499;
    let batch = db.batch();
    let batchCount = 0;
    let totalReset = 0;

    for (const merchantDoc of merchantsSnap.docs) {
      const data = merchantDoc.data() ?? {};
      // Skip merchants that already have a zero count to avoid unnecessary writes.
      if ((data.weekly_notif_sent_count ?? 0) === 0) continue;

      batch.update(merchantDoc.ref, { weekly_notif_sent_count: 0 });
      batchCount++;
      totalReset++;

      if (batchCount >= BATCH_SIZE) {
        await batch.commit();
        batch = db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    functions.logger.info(`Weekly quota reset complete: ${totalReset} merchants reset`);
    return null;
  });

// ─── 5. Daily scheduled triggers (birthday, anniversary, inactive) ───────────

/**
 * Runs every day at 09:00 UTC.
 * Handles birthday, anniversary of connection, and inactive client triggers.
 * NOTE: these require user.date_of_birth and follow date data in user profiles.
 */
export const dailyScheduledTriggers = functions
  .region("europe-west1")
  .pubsub.schedule("0 9 * * *")
  .timeZone("Europe/Paris")
  .onRun(async (_context) => {
    functions.logger.info("Running daily scheduled triggers");

    const now = new Date();
    const todayMD = `${String(now.getMonth() + 1).padStart(2, "0")}-${String(
      now.getDate()
    ).padStart(2, "0")}`;

    // Scan all merchants that have enabled auto notifications for birthday/anniversary.
    const merchantsSnap = await db.collection("merchants").get();

    for (const merchantDoc of merchantsSnap.docs) {
      const merchantId = merchantDoc.id;

      // Check if this merchant has birthday notifications enabled.
      const birthdayNotifs = await getEnabledNotifications(
        merchantId,
        "Date anniversaire client"
      );
      const anniversaryNotifs = await getEnabledNotifications(
        merchantId,
        "Anniversaire de connexion"
      );
      const inactiveNotifs = await getEnabledNotifications(
        merchantId,
        "Retour d'un client inactif"
      );

      if (
        birthdayNotifs.length === 0 &&
        anniversaryNotifs.length === 0 &&
        inactiveNotifs.length === 0
      ) {
        continue;
      }

      // Get all followers.
      const followerIds = await getFollowerIds(merchantId);

      for (const clientId of followerIds) {
        const userSnap = await db.collection("users").doc(clientId).get();
        const userData = userSnap.data() ?? {};

        // Birthday trigger.
        if (birthdayNotifs.length > 0 && userData.date_of_birth) {
          const dob: string = userData.date_of_birth; // expected "MM-DD" or "YYYY-MM-DD"
          const dobMD = dob.length >= 5 ? dob.slice(dob.length - 5) : dob;
          if (dobMD === todayMD) {
            for (const notifDoc of birthdayNotifs) {
              const allowed = await shouldSendToClient(notifDoc, clientId, merchantId);
              if (!allowed) continue;
              await fireAutoNotification(notifDoc, merchantId, clientId).catch(
                (e) => functions.logger.warn("Birthday notif error", { e })
              );
            }
          }
        }

        // Anniversary of first connection.
        if (anniversaryNotifs.length > 0) {
          const followedMerchantSnap = await db
            .collection("users")
            .doc(clientId)
            .collection("followed_merchants")
            .doc(merchantId)
            .get();
          if (followedMerchantSnap.exists) {
            const followedAt: FirebaseFirestore.Timestamp | undefined =
              followedMerchantSnap.data()?.followed_at;
            if (followedAt) {
              const followDate = followedAt.toDate();
              const followMD = `${String(followDate.getMonth() + 1).padStart(
                2,
                "0"
              )}-${String(followDate.getDate()).padStart(2, "0")}`;
              // Only trigger after the first year.
              if (followMD === todayMD && now.getFullYear() > followDate.getFullYear()) {
                for (const notifDoc of anniversaryNotifs) {
                  const allowed = await shouldSendToClient(notifDoc, clientId, merchantId);
                  if (!allowed) continue;
                  await fireAutoNotification(
                    notifDoc,
                    merchantId,
                    clientId
                  ).catch((e) =>
                    functions.logger.warn("Anniversary notif error", { e })
                  );
                }
              }
            }
          }
        }

        // Inactive client — no visit in last 60 days (aligned with Flutter threshold).
        if (inactiveNotifs.length > 0) {
          const loyaltySnap = await db
            .collection("merchants")
            .doc(merchantId)
            .collection("loyalty_clients")
            .doc(clientId)
            .get();
          if (loyaltySnap.exists) {
            const updatedAt: FirebaseFirestore.Timestamp | undefined =
              loyaltySnap.data()?.updated_at;
            if (updatedAt) {
              const daysSinceVisit =
                (now.getTime() - updatedAt.toDate().getTime()) /
                (1000 * 60 * 60 * 24);
              if (daysSinceVisit >= 60) {
                for (const notifDoc of inactiveNotifs) {
                  const allowed = await shouldSendToClient(notifDoc, clientId, merchantId);
                  if (!allowed) continue;
                  await fireAutoNotification(
                    notifDoc,
                    merchantId,
                    clientId
                  ).catch((e) =>
                    functions.logger.warn("Inactive notif error", { e })
                  );
                }
              }
            }
          }
        }
      }
    }

    return null;
  });
