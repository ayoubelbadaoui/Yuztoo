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
 * Compute the CRM segment key for a follower based on their heart_level and
 * the date they started following.
 *
 * Mirrors the Flutter `ClientSegment` logic in
 * `lib/feature/client_list/domain/entities/merchant_client_row.dart`:
 *   - heartLevel >= 3  → 'vip'
 *   - heartLevel >= 2  → 'habitue'
 *   - followed < 14 days ago → 'nouveau'
 *   - default → 'abonne'
 *
 * Exported for unit testing; intentionally pure (no Firebase calls).
 */
export function computeSegment(heartLevel: number, followedAt: Date | null): string {
  if (heartLevel >= 3) return "vip";
  if (heartLevel >= 2) return "habitue";
  if (followedAt !== null) {
    const daysSinceFollow =
      (Date.now() - followedAt.getTime()) / (1000 * 60 * 60 * 24);
    if (daysSinceFollow < 14) return "nouveau";
  }
  return "abonne";
}

/**
 * Returns the CRM segment key for a follower of a specific merchant.
 * Reads the `users/{clientId}/followed_merchants/{merchantId}` document.
 */
async function getClientSegment(
  clientId: string,
  merchantId: string
): Promise<string> {
  try {
    const doc = await db
      .collection("users")
      .doc(clientId)
      .collection("followed_merchants")
      .doc(merchantId)
      .get();
    if (!doc.exists) return "abonne";
    const data = doc.data() ?? {};
    const heartLevel: number =
      typeof data.heart_level === "number" ? data.heart_level : 1;
    const followedAtTs: FirebaseFirestore.Timestamp | undefined =
      data.followed_at;
    const followedAt: Date | null = followedAtTs
      ? followedAtTs.toDate()
      : null;
    return computeSegment(heartLevel, followedAt);
  } catch {
    return "abonne";
  }
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
      type: "auto",
      title: merchantName,
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
    const data = notifDoc.data();
    const audience: string = data.audience ?? "Tous mes clients";
    const segments: string[] = data.target_segments ?? [];

    // Skip "Certains clients" notifications that have no segments specified.
    if (audience !== "Tous mes clients" && segments.length === 0) continue;

    for (const clientId of clientIds) {
      // Segment filtering: when audience is "Certains clients" check the
      // follower's CRM segment (heartLevel + followedAt) against the list.
      if (audience === "Certains clients" && segments.length > 0) {
        const clientSegment = await getClientSegment(clientId, merchantId);
        if (!segments.includes(clientSegment)) continue;
      }

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
        payload: { aps: { sound: "default", badge: 1 } },
      },
    };

    try {
      await messaging.send(message);
      functions.logger.info("Push sent", { userId, notificationId });
    } catch (error: any) {
      if (
        error?.errorInfo?.code ===
          "messaging/registration-token-not-registered" ||
        error?.errorInfo?.code === "messaging/invalid-registration-token"
      ) {
        await tokenDoc.ref.delete();
      } else {
        functions.logger.error("Failed to send push", { userId, error });
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
 * Triggers: "Chaque promotion créé"
 */
export const onPromotionCreated = functions
  .region("europe-west1")
  .firestore.document("merchants/{merchantId}/promotions/{promoId}")
  .onCreate(async (_snap, context) => {
    const { merchantId } = context.params;
    await dispatchTrigger(merchantId, "Chaque promotion créé");
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

        // Inactive client (no visit in last 90 days).
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
              if (daysSinceVisit >= 90) {
                for (const notifDoc of inactiveNotifs) {
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
