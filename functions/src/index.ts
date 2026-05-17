import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {
  AUTO_NOTIFICATION_TRIGGERS,
  autoNotificationSegmentMatches,
  filterEnabledNotificationsForTrigger,
  isMerchantAutoNotificationsEnabled,
  shouldSendBirthdayThisYear,
  shouldSendConnectionAnniversary,
  shouldSendInactiveReturn,
} from "./auto_notification_core";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─── helpers ──────────────────────────────────────────────────────────────────

/**
 * Process an array of items with a bounded concurrency limit.
 * Prevents spawning thousands of simultaneous Firestore reads (G8 fix).
 */
async function processInChunks<T>(
  items: T[],
  concurrency: number,
  fn: (item: T) => Promise<void>
): Promise<void> {
  for (let i = 0; i < items.length; i += concurrency) {
    await Promise.all(items.slice(i, i + concurrency).map(fn));
  }
}

/**
 * Fetch enabled auto_notifications for a merchant matching a trigger (canonical
 * or legacy alias). Single-field query — no composite index on (is_enabled, trigger).
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
    .get();
  return filterEnabledNotificationsForTrigger(snap.docs, trigger);
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

// ─── Loyalty bon helpers ─────────────────────────────────────────────────────
//
// Persisted reward bons live at users/{clientId}/loyalty_bons/{bonId}. Schema:
//   merchant_id, kind ('welcome' | 'milestone'), description (snapshotted),
//   issued_at, valid_until_at (nullable — null = evergreen), redeemed_at,
//   notified_expiring_at, notified_expired_at.
// Welcome bons use a deterministic ID (`welcome_${merchantId}`) so issuance is
// naturally idempotent across CF retries. Milestone bons use random IDs but
// the issuer pre-checks for an active (unredeemed) one before creating.

/**
 * Compute valid_until_at from a merchant's loyalty config.
 * Returns null when the merchant has not enabled validity (evergreen bon).
 *
 * Exported so unit tests can verify the (config) → (timestamp | null)
 * mapping without spinning up Firestore.
 */
export function computeBonValidUntil(
  loyaltyConfig: Record<string, unknown> | undefined
): admin.firestore.Timestamp | null {
  if (!loyaltyConfig) return null;
  const enabled = Boolean(loyaltyConfig.reward_validity_enabled);
  const days = Number(loyaltyConfig.reward_validity_days ?? 0);
  if (!enabled || !Number.isFinite(days) || days <= 0) return null;
  const ms = Date.now() + days * 24 * 60 * 60 * 1000;
  return admin.firestore.Timestamp.fromMillis(ms);
}

/**
 * Issue a welcome bon doc when a client first appears in a merchant's
 * loyalty_clients (first_visit_at). Idempotent: deterministic ID +
 * existence check. No-op when the merchant has no welcome gift configured.
 */
async function issueWelcomeBonIfEligible(
  clientId: string,
  merchantId: string,
  merchantData: Record<string, unknown>
): Promise<void> {
  const welcomeGift = String(
    merchantData.welcome_gift_description ?? ""
  ).trim();
  if (welcomeGift.length === 0) return;
  const bonId = `welcome_${merchantId}`;
  const ref = db
    .collection("users")
    .doc(clientId)
    .collection("loyalty_bons")
    .doc(bonId);
  try {
    const existing = await ref.get();
    if (existing.exists) return;
    const loyaltyConfig =
      (merchantData.loyalty_program as Record<string, unknown>) ?? {};
    const validUntil = computeBonValidUntil(loyaltyConfig);
    await ref.set({
      merchant_id: merchantId,
      kind: "welcome",
      description: welcomeGift,
      issued_at: admin.firestore.FieldValue.serverTimestamp(),
      valid_until_at: validUntil,
      redeemed_at: null,
      notified_expiring_at: null,
      notified_expired_at: null,
    });
  } catch (e) {
    functions.logger.warn("issueWelcomeBon failed", {
      clientId,
      merchantId,
      error: e,
    });
  }
}

/**
 * Issue a milestone bon doc when a client crosses the threshold AND there
 * is no other active (unredeemed) milestone bon for this client+merchant
 * pair. The latter constraint avoids duplicates if the trigger fires twice
 * (CF retry, write amplification, etc.).
 */
async function issueMilestoneBonIfEligible(
  clientId: string,
  merchantId: string,
  merchantData: Record<string, unknown>
): Promise<void> {
  const ref = db
    .collection("users")
    .doc(clientId)
    .collection("loyalty_bons");
  try {
    // Active (unredeemed) milestone bon for this merchant?
    const existing = await ref
      .where("merchant_id", "==", merchantId)
      .where("kind", "==", "milestone")
      .where("redeemed_at", "==", null)
      .limit(1)
      .get();
    if (!existing.empty) return;
    const loyaltyConfig =
      (merchantData.loyalty_program as Record<string, unknown>) ?? {};
    const description = String(merchantData.name ?? "Bon fidélité");
    const validUntil = computeBonValidUntil(loyaltyConfig);
    await ref.add({
      merchant_id: merchantId,
      kind: "milestone",
      description: `Bon fidélité — ${description}`,
      issued_at: admin.firestore.FieldValue.serverTimestamp(),
      valid_until_at: validUntil,
      redeemed_at: null,
      notified_expiring_at: null,
      notified_expired_at: null,
    });
  } catch (e) {
    functions.logger.warn("issueMilestoneBon failed", {
      clientId,
      merchantId,
      error: e,
    });
  }
}

/**
 * Mark the (single) active bon of a given kind as redeemed for a
 * client+merchant pair. Used when the merchant decrements
 * validated_passages (milestone redemption) or when the client claims
 * the welcome bon (welcome_bon_claimed_at transitions null→set).
 */
async function markActiveBonRedeemed(
  clientId: string,
  merchantId: string,
  kind: "welcome" | "milestone"
): Promise<void> {
  try {
    const snap = await db
      .collection("users")
      .doc(clientId)
      .collection("loyalty_bons")
      .where("merchant_id", "==", merchantId)
      .where("kind", "==", kind)
      .where("redeemed_at", "==", null)
      .limit(1)
      .get();
    if (snap.empty) return;
    await snap.docs[0].ref.update({
      redeemed_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e) {
    functions.logger.warn("markActiveBonRedeemed failed", {
      clientId,
      merchantId,
      kind,
      error: e,
    });
  }
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

/** Loyalty doc snapshot → segment (for onWrite before/after). */
function computeSegmentFromLoyaltyData(
  data: Record<string, unknown>
): string {
  const validatedPassages =
    typeof data.validated_passages === "number" ? data.validated_passages : 0;
  const updatedAt = data.updated_at as
    | FirebaseFirestore.Timestamp
    | undefined;
  const daysSinceLastVisit = updatedAt
    ? (Date.now() - updatedAt.toDate().getTime()) / (1000 * 60 * 60 * 24)
    : 999;
  return computeSegment(validatedPassages, daysSinceLastVisit);
}

const KNOWN_CLIENT_SEGMENTS = new Set([
  "vip",
  "habitue",
  "nouveau",
  "inactif",
  "abonne",
]);

/**
 * Passage-based segment from `loyalty_clients` only (no manual override).
 */
async function getClientSegmentFromLoyalty(
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
    const daysSinceLastVisit = updatedAt
      ? (Date.now() - updatedAt.toDate().getTime()) / (1000 * 60 * 60 * 24)
      : 999;
    return computeSegment(validatedPassages, daysSinceLastVisit);
  } catch (e) {
    functions.logger.warn("getClientSegmentFromLoyalty error", {
      clientId,
      merchantId,
      error: e,
    });
    return "nouveau";
  }
}

/**
 * Effective CRM segment for ciblage: `manual_segment` on
 * `merchants/{merchantId}/clients/{clientId}` wins over loyalty auto-compute.
 */
async function getClientSegment(
  clientId: string,
  merchantId: string
): Promise<string> {
  try {
    const overrideSnap = await db
      .collection("merchants")
      .doc(merchantId)
      .collection("clients")
      .doc(clientId)
      .get();
    const manual = overrideSnap.data()?.manual_segment;
    if (typeof manual === "string") {
      const trimmed = manual.trim();
      if (trimmed.length > 0 && KNOWN_CLIENT_SEGMENTS.has(trimmed)) {
        return trimmed;
      }
    }
  } catch (e) {
    functions.logger.warn("getClientSegment manual_segment read failed", {
      clientId,
      merchantId,
      error: e,
    });
  }
  return getClientSegmentFromLoyalty(clientId, merchantId);
}

/** Batch-load manual_segment overrides for promotion fan-out. */
async function loadManualSegmentOverrides(
  merchantId: string
): Promise<Record<string, string>> {
  const map: Record<string, string> = {};
  try {
    const snap = await db
      .collection("merchants")
      .doc(merchantId)
      .collection("clients")
      .get();
    for (const doc of snap.docs) {
      const manual = doc.data()?.manual_segment;
      if (typeof manual === "string") {
        const trimmed = manual.trim();
        if (trimmed.length > 0 && KNOWN_CLIENT_SEGMENTS.has(trimmed)) {
          map[doc.id] = trimmed;
        }
      }
    }
  } catch (e) {
    functions.logger.warn("loadManualSegmentOverrides failed", {
      merchantId,
      error: e,
    });
  }
  return map;
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
async function isMerchantBlockedByClient(
  clientId: string,
  merchantId: string
): Promise<boolean> {
  try {
    const snap = await db
      .collection("users")
      .doc(clientId)
      .collection("blocked_merchants")
      .doc(merchantId)
      .get();
    return snap.exists;
  } catch (e) {
    functions.logger.warn("isMerchantBlockedByClient: lookup failed", {
      clientId,
      merchantId,
      error: e,
    });
    // Fail-safe: when the lookup itself errors, default to NOT blocked so
    // legitimate clients still get their notifications. The block is a
    // user opt-in feature; missing it once is far less harmful than
    // silencing every notification because of a transient Firestore blip.
    return false;
  }
}

async function shouldSendToClient(
  notifDoc: admin.firestore.QueryDocumentSnapshot,
  clientId: string,
  merchantId: string
): Promise<boolean> {
  // Hard gate: a client who blocked this merchant must NEVER receive any
  // automated notification from them — segment match or not. Checked first
  // so we short-circuit the more expensive segment lookup.
  if (await isMerchantBlockedByClient(clientId, merchantId)) return false;

  const data = notifDoc.data();
  const audience: string = data.audience ?? "Tous mes clients";
  const rawSegments: string[] = data.target_segments ?? [];

  if (audience !== "Certains clients" || rawSegments.length === 0) return true;

  const clientSegment = await getClientSegment(clientId, merchantId);
  return autoNotificationSegmentMatches(clientSegment, rawSegments);
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
  const merchantSnap = await db.collection("merchants").doc(merchantId).get();
  if (!merchantSnap.exists) return;
  if (!isMerchantAutoNotificationsEnabled(merchantSnap.data())) {
    functions.logger.info("dispatchTrigger skipped — auto-notifs disabled", {
      merchantId,
      trigger,
    });
    return;
  }

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
        // Wrap in try/catch: if delete() fails (network error, permission issue),
        // the CF would fail and GCP would retry, leading to a retry loop where
        // messaging.send() fails again → delete() fails again → infinite retries.
        await tokenDoc.ref.delete().catch((deleteErr) => {
          functions.logger.error("Failed to delete dead FCM token", {
            userId,
            code,
            deleteErr,
          });
        });
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
    await dispatchTrigger(
      merchantId,
      AUTO_NOTIFICATION_TRIGGERS.newFollower,
      clientId
    );
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

    // ── G3 fix: server-side auto-follow on first loyalty passage ─────────────
    // When the app is killed between recording a passage and calling
    // toggleMerchantFollow, the follow document is silently lost.
    // This server-side trigger creates it idempotently — it is not subject to
    // app lifecycle and runs even if the client device is offline.
    // Creating the follow doc triggers onFollowedMerchantCreated → fires
    // "Nouveau client connecté" auto-notifications (correct first-contact UX).
    if (!change.before.exists) {
      try {
        const followRef = db
          .collection("users")
          .doc(clientId)
          .collection("followed_merchants")
          .doc(merchantId);
        const followSnap = await followRef.get();
        if (!followSnap.exists) {
          await followRef.set({
            merchant_id: merchantId,
            followed_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          functions.logger.info("Auto-follow created via loyalty passage", {
            clientId,
            merchantId,
          });
        }
      } catch (e) {
        // Non-fatal — passage is still recorded, follow will retry on next
        // passage if the client returns. Log and continue.
        functions.logger.error("onLoyaltyProgressUpdated: auto-follow failed", {
          clientId,
          merchantId,
          error: e,
        });
      }
    }
    // ─────────────────────────────────────────────────────────────────────────

    const beforeValidated: number = before.validated_passages ?? 0;
    const afterValidated: number = after.validated_passages ?? 0;

    if (change.before.exists) {
      const segmentBefore = computeSegmentFromLoyaltyData(before);
      const segmentAfter = computeSegmentFromLoyaltyData(after);
      if (segmentBefore !== segmentAfter) {
        await dispatchTrigger(
          merchantId,
          AUTO_NOTIFICATION_TRIGGERS.segmentChange,
          clientId
        );
      }
    }

    // ── Welcome bon issuance (first visit only) ──────────────────────────────
    // Tied to the same `!change.before.exists` predicate the auto-follow
    // branch uses — this is the canonical "first visit" boundary.
    if (!change.before.exists) {
      try {
        const merchantSnap = await db
          .collection("merchants")
          .doc(merchantId)
          .get();
        const merchantData = merchantSnap.data() ?? {};
        await issueWelcomeBonIfEligible(clientId, merchantId, merchantData);
      } catch (e) {
        functions.logger.warn("welcome bon issuance lookup failed", {
          clientId,
          merchantId,
          error: e,
        });
      }
    }

    // ── Welcome bon redemption (client tapped "Utiliser") ────────────────────
    // The `welcome_bon_claimed_at` field is set by the existing welcome-claim
    // path (FirestoreClientLoyaltyRepository.claimWelcomeBon). Mirror the
    // claim onto the bon doc so the UI sees a coherent state.
    if (!before.welcome_bon_claimed_at && after.welcome_bon_claimed_at) {
      await markActiveBonRedeemed(clientId, merchantId, "welcome");
    }

    // Passage was just validated (increment).
    if (afterValidated > beforeValidated) {
      await dispatchTrigger(
        merchantId,
        AUTO_NOTIFICATION_TRIGGERS.passageValidated,
        clientId
      );

      // Check if reward is now available — requires merchant loyalty config.
      const merchantSnap = await db
        .collection("merchants")
        .doc(merchantId)
        .get();
      const merchantData = merchantSnap.data() ?? {};
      const loyaltyConfig = merchantData.loyalty_program ?? {};
      const visitsRequired: number =
        loyaltyConfig.visits_required ?? loyaltyConfig.visit_count ?? 10;

      if (afterValidated >= visitsRequired) {
        // Reward unlocked.
        await dispatchTrigger(
          merchantId,
          AUTO_NOTIFICATION_TRIGGERS.rewardAvailable,
          clientId
        );
        // Persist a milestone bon doc so the scheduled expiration scan
        // can warn / expire it later. Idempotent — won't re-issue if an
        // active one already exists.
        await issueMilestoneBonIfEligible(clientId, merchantId, merchantData);
      } else if (afterValidated === visitsRequired - 1) {
        // One step away from reward.
        await dispatchTrigger(
          merchantId,
          AUTO_NOTIFICATION_TRIGGERS.rewardNear,
          clientId
        );
      }
    }

    // ── Milestone bon redemption (merchant honored the bon) ──────────────────
    // RedeemLoyaltyReward decrements validated_passages by `visitsRequired`.
    // Any decrement is treated as a redemption signal so the active bon is
    // marked as redeemed. Safe even on edge cases (manual correction, etc.):
    // markActiveBonRedeemed is a no-op when no active bon exists.
    if (afterValidated < beforeValidated) {
      await markActiveBonRedeemed(clientId, merchantId, "milestone");
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
 *   - On segment read failure we resolve each follower via [getClientSegment]
 *     (same as manual notifications) instead of broadcasting to all.
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

        // Build segment map: clientId → segment (loyalty + manual overrides).
        const segmentMap: Record<string, string> = {};
        for (const doc of loyaltySnap.docs) {
          const d = doc.data() ?? {};
          const validated: number =
            typeof d.validated_passages === "number" ? d.validated_passages : 0;
          const lastPassageAt = d.last_passage_at as
            | FirebaseFirestore.Timestamp
            | undefined;
          const updatedAt = d.updated_at as
            | FirebaseFirestore.Timestamp
            | undefined;
          const anchor = lastPassageAt ?? updatedAt;
          const days = anchor
            ? (Date.now() - anchor.toDate().getTime()) / (1000 * 60 * 60 * 24)
            : 999;
          segmentMap[doc.id] = computeSegment(validated, days);
        }
        const manualOverrides = await loadManualSegmentOverrides(merchantId);
        for (const [clientId, seg] of Object.entries(manualOverrides)) {
          segmentMap[clientId] = seg;
        }

        targetIds = followerIds.filter((clientId) => {
          const seg = segmentMap[clientId] ?? "nouveau";
          return autoNotificationSegmentMatches(seg, targetSegments);
        });
      } catch (e) {
        functions.logger.warn(
          "onPromotionCreated: bulk segment load failed, per-client fallback",
          { merchantId, promoId, error: e }
        );
        const filtered: string[] = [];
        await processInChunks(followerIds, 16, async (clientId) => {
          const seg = await getClientSegment(clientId, merchantId);
          if (autoNotificationSegmentMatches(seg, targetSegments)) {
            filtered.push(clientId);
          }
        });
        targetIds = filtered;
      }
    }

    if (targetIds.length === 0) return null;

    // 2b. Drop clients who blocked this merchant — they must NEVER receive
    //     a promo from a merchant they silenced. Done here (before the doc
    //     write) so we don't even create the notification document, which
    //     also prevents the onNotificationCreated FCM push.
    if (targetIds.length > 0) {
      const filtered: string[] = [];
      await processInChunks(targetIds, 16, async (clientId) => {
        const blocked = await isMerchantBlockedByClient(clientId, merchantId);
        if (!blocked) filtered.push(clientId);
      });
      targetIds = filtered;
    }
    if (targetIds.length === 0) return null;

    // 3. Write one type:"promotion" notification per eligible follower.
    //    onNotificationCreated will forward the FCM push for each doc.
    const BATCH_SIZE = 499;
    let batch = db.batch();
    let batchCount = 0;

    for (const clientId of targetIds) {
      // Deterministic doc ID = promo_{promoId} so that if GCP fires this
      // trigger twice (at-least-once delivery), the second batch.set() is a
      // no-op overwrite on the same document.  onNotificationCreated is an
      // onCreate trigger — it only fires on the first creation, so no
      // duplicate push is sent on a retry invocation.
      const notifRef = db
        .collection("users")
        .doc(clientId)
        .collection("notifications")
        .doc(`promo_${promoId}`);

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
        // G7 fix: wrap each commit in try/catch so a single batch failure
        // does not prevent the remaining merchants from being reset.
        // Affected merchants in a failed batch stay at their current count
        // until the next Monday — far better than blocking all merchants.
        try {
          await batch.commit();
        } catch (e) {
          functions.logger.error("weeklyQuotaReset: batch commit failed", {
            failedMerchantCount: batchCount,
            error: e,
          });
        }
        batch = db.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      try {
        await batch.commit();
      } catch (e) {
        functions.logger.error("weeklyQuotaReset: final batch commit failed", {
          failedMerchantCount: batchCount,
          error: e,
        });
      }
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
    // G8 fix: process merchants with bounded concurrency (10 at a time) instead of
    // sequential await. At 1000 merchants × 500 followers, the old sequential loop
    // would take ~25,000 seconds — far beyond the 9-minute CF timeout.
    // With MERCHANT_CONCURRENCY=10 and CLIENT_CONCURRENCY=50, worst-case is:
    //   ceil(1000/10) * ceil(500/50) * ~50ms ≈ 50,000ms < 9 minutes.
    const merchantsSnap = await db.collection("merchants").get();
    const MERCHANT_CONCURRENCY = 10;
    const CLIENT_CONCURRENCY = 50;

    await processInChunks(
      merchantsSnap.docs,
      MERCHANT_CONCURRENCY,
      async (merchantDoc) => {
        const merchantId = merchantDoc.id;
        const merchantData = merchantDoc.data() ?? {};

        if (!isMerchantAutoNotificationsEnabled(merchantData)) {
          return;
        }

        // Fetch all 3 trigger types in parallel (was 3 sequential awaits).
        const [birthdayNotifs, anniversaryNotifs, inactiveNotifs] =
          await Promise.all([
            getEnabledNotifications(
              merchantId,
              AUTO_NOTIFICATION_TRIGGERS.birthday
            ),
            getEnabledNotifications(
              merchantId,
              AUTO_NOTIFICATION_TRIGGERS.connectionAnniversary
            ),
            getEnabledNotifications(
              merchantId,
              AUTO_NOTIFICATION_TRIGGERS.inactiveReturn
            ),
          ]);

        if (
          birthdayNotifs.length === 0 &&
          anniversaryNotifs.length === 0 &&
          inactiveNotifs.length === 0
        ) {
          return;
        }

        // Get all followers.
        const followerIds = await getFollowerIds(merchantId);

        // Process clients with bounded concurrency within each merchant.
        await processInChunks(
          followerIds,
          CLIENT_CONCURRENCY,
          async (clientId) => {
            try {
              const userSnap = await db
                .collection("users")
                .doc(clientId)
                .get();
              const userData = userSnap.data() ?? {};

              const followRef = db
                .collection("users")
                .doc(clientId)
                .collection("followed_merchants")
                .doc(merchantId);
              const followedMerchantSnap = await followRef.get();
              const followData = followedMerchantSnap.data() ?? {};

              // Birthday trigger — once per calendar year per client/merchant.
              if (birthdayNotifs.length > 0) {
                const dob = userData.date_of_birth as string | undefined;
                const lastBirthdayYear = followData.last_birthday_auto_year as
                  | number
                  | undefined;
                if (
                  shouldSendBirthdayThisYear(
                    dob,
                    todayMD,
                    now,
                    lastBirthdayYear
                  )
                ) {
                  let sentBirthday = false;
                  for (const notifDoc of birthdayNotifs) {
                    const allowed = await shouldSendToClient(
                      notifDoc,
                      clientId,
                      merchantId
                    );
                    if (!allowed) continue;
                    await fireAutoNotification(
                      notifDoc,
                      merchantId,
                      clientId
                    ).catch((e) =>
                      functions.logger.warn("Birthday notif error", { e })
                    );
                    sentBirthday = true;
                  }
                  if (sentBirthday) {
                    await followRef.set(
                      { last_birthday_auto_year: now.getFullYear() },
                      { merge: true }
                    );
                  }
                }
              }

              // Anniversary of first connection — once per calendar year.
              if (anniversaryNotifs.length > 0 && followedMerchantSnap.exists) {
                const followedAt: FirebaseFirestore.Timestamp | undefined =
                  followData.followed_at;
                if (followedAt) {
                  const followDate = followedAt.toDate();
                  const followMD = `${String(followDate.getMonth() + 1).padStart(
                    2,
                    "0"
                  )}-${String(followDate.getDate()).padStart(2, "0")}`;
                  const lastAnniversaryYear =
                    followData.last_connection_anniversary_year as
                      | number
                      | undefined;
                  if (
                    shouldSendConnectionAnniversary(
                      followMD,
                      todayMD,
                      followDate.getFullYear(),
                      now.getFullYear(),
                      lastAnniversaryYear
                    )
                  ) {
                    let sentAnniversary = false;
                    for (const notifDoc of anniversaryNotifs) {
                      const allowed = await shouldSendToClient(
                        notifDoc,
                        clientId,
                        merchantId
                      );
                      if (!allowed) continue;
                      await fireAutoNotification(
                        notifDoc,
                        merchantId,
                        clientId
                      ).catch((e) =>
                        functions.logger.warn("Anniversary notif error", {
                          e,
                        })
                      );
                      sentAnniversary = true;
                    }
                    if (sentAnniversary) {
                      await followRef.set(
                        {
                          last_connection_anniversary_year: now.getFullYear(),
                        },
                        { merge: true }
                      );
                    }
                  }
                }
              }

              // Inactive client — ≥60 days without visit, max once per 30 days.
              if (inactiveNotifs.length > 0) {
                const loyaltyRef = db
                  .collection("merchants")
                  .doc(merchantId)
                  .collection("loyalty_clients")
                  .doc(clientId);
                const loyaltySnap = await loyaltyRef.get();
                if (loyaltySnap.exists) {
                  const loyaltyData = loyaltySnap.data() ?? {};
                  const updatedAt: FirebaseFirestore.Timestamp | undefined =
                    loyaltyData.updated_at;
                  if (updatedAt) {
                    const daysSinceVisit =
                      (now.getTime() - updatedAt.toDate().getTime()) /
                      (1000 * 60 * 60 * 24);
                    const lastInactiveAt = loyaltyData.last_inactive_auto_at as
                      | FirebaseFirestore.Timestamp
                      | undefined;
                    const lastInactiveMs = lastInactiveAt?.toMillis();
                    if (
                      shouldSendInactiveReturn(
                        daysSinceVisit,
                        lastInactiveMs,
                        now.getTime()
                      )
                    ) {
                      let sentInactive = false;
                      for (const notifDoc of inactiveNotifs) {
                        const allowed = await shouldSendToClient(
                          notifDoc,
                          clientId,
                          merchantId
                        );
                        if (!allowed) continue;
                        await fireAutoNotification(
                          notifDoc,
                          merchantId,
                          clientId
                        ).catch((e) =>
                          functions.logger.warn("Inactive notif error", { e })
                        );
                        sentInactive = true;
                      }
                      if (sentInactive) {
                        await loyaltyRef.set(
                          {
                            last_inactive_auto_at:
                              admin.firestore.FieldValue.serverTimestamp(),
                          },
                          { merge: true }
                        );
                      }
                    }
                  }
                }
              }
            } catch (e) {
              // Per-client errors are isolated — one bad client doc does not
              // block the rest of the fan-out for this merchant.
              functions.logger.error(
                "dailyScheduledTriggers: error processing client",
                { clientId, merchantId, error: e }
              );
            }
          }
        );
      }
    );

    return null;
  });

// ─── 5b. New merchant partner ─────────────────────────────────────────────────

/**
 * Fires when a merchant adds a recommended partner on their vitrine.
 * Trigger: "Nouveau partenaire" → all eligible followers.
 */
export const onMerchantPartnerCreated = functions
  .region("europe-west1")
  .firestore.document("merchants/{merchantId}/partners/{partnerId}")
  .onCreate(async (_snap, context) => {
    const { merchantId } = context.params;
    await dispatchTrigger(merchantId, AUTO_NOTIFICATION_TRIGGERS.newPartner);
    return null;
  });

// ─── 5c. Exceptional closure flag on merchant hours ─────────────────────────

/**
 * When a merchant toggles `hasExceptionalClosure` on their hours map,
 * notify followers once.
 */
export const onMerchantHoursUpdated = functions
  .region("europe-west1")
  .firestore.document("merchants/{merchantId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() ?? {};
    const after = change.after.data() ?? {};
    if (!isMerchantAutoNotificationsEnabled(after)) return null;

    const beforeHours = before.hours as Record<string, unknown> | undefined;
    const afterHours = after.hours as Record<string, unknown> | undefined;
    const wasClosed = beforeHours?.hasExceptionalClosure === true;
    const isClosed = afterHours?.hasExceptionalClosure === true;
    if (!wasClosed && isClosed) {
      await dispatchTrigger(
        context.params.merchantId,
        AUTO_NOTIFICATION_TRIGGERS.exceptionalClosure
      );
    }
    return null;
  });

// ─── 7. Daily bon expiration scan ────────────────────────────────────────────
//
// Counterpart to `onLoyaltyProgressUpdated` issuance: scans every active
// (unredeemed) loyalty bon across all users via collection-group query
// and pushes two kinds of notification:
//
//   • "expire bientôt" — bon whose valid_until_at falls in the next
//     three days, idempotently marked via notified_expiring_at.
//   • "expiré"          — bon whose valid_until_at has already passed,
//     idempotently marked via notified_expired_at.
//
// Idempotency is essential because Firestore's pubsub schedule offers
// at-least-once delivery — without the markers we'd notify twice on a
// retry. The markers themselves act as the cursor: any bon whose
// notified_*_at is already set is excluded from the result set on the
// next run.
//
// Bons without a valid_until_at (evergreen — merchant did not enable
// validity) are filtered out by the index; they never expire and never
// generate alerts.
//
// Scheduled at the SAME 09:00 Europe/Paris slot as the existing
// dailyScheduledTriggers — keeps "user-visible activity" centred at one
// predictable time of day rather than dripping notifications at random
// hours.
//
// Required Firestore index: collection-group `loyalty_bons` on
// (redeemed_at ASC, notified_expired_at ASC, valid_until_at ASC) for the
// expired query, and a parallel one with notified_expiring_at for the
// expiring query. Deploy via `firebase deploy --only firestore:indexes`
// after adding the entries to firestore.indexes.json.
export const dailyBonExpirationScan = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 540, memory: "512MB" })
  .pubsub.schedule("0 9 * * *")
  .timeZone("Europe/Paris")
  .onRun(async () => {
    functions.logger.info("Running daily bon expiration scan");
    const now = admin.firestore.Timestamp.now();
    const inThreeDays = admin.firestore.Timestamp.fromMillis(
      now.toMillis() + 3 * 24 * 60 * 60 * 1000
    );

    // 1) Bons that have expired and weren't notified yet.
    let expiredCount = 0;
    try {
      const expiredSnap = await db
        .collectionGroup("loyalty_bons")
        .where("redeemed_at", "==", null)
        .where("notified_expired_at", "==", null)
        .where("valid_until_at", "<=", now)
        .get();
      await processInChunks(expiredSnap.docs, 20, async (doc) => {
        const userId = doc.ref.parent.parent?.id;
        if (!userId) return;
        const data = doc.data();
        const merchantId = String(data.merchant_id ?? "");
        const description = String(data.description ?? "votre bon fidélité");
        try {
          // Push notification — write to user's notifications subcollection,
          // onNotificationCreated forwards the FCM push.
          await db
            .collection("users")
            .doc(userId)
            .collection("notifications")
            .add({
              client_id: userId,
              merchant_id: merchantId,
              merchant_name: "",
              type: "bon_expired",
              title: "Bon expiré",
              body: `${description} a expiré.`,
              is_read: false,
              created_at: admin.firestore.FieldValue.serverTimestamp(),
            });
          await doc.ref.update({
            notified_expired_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          expiredCount++;
        } catch (e) {
          functions.logger.warn("expired-bon notify failed", {
            userId,
            bonId: doc.id,
            error: e,
          });
        }
      });
    } catch (e) {
      functions.logger.error("expired bon scan failed", { error: e });
    }

    // 2) Bons expiring within 3 days, not yet notified, not yet expired.
    let expiringCount = 0;
    try {
      const expiringSnap = await db
        .collectionGroup("loyalty_bons")
        .where("redeemed_at", "==", null)
        .where("notified_expiring_at", "==", null)
        .where("valid_until_at", "<=", inThreeDays)
        .where("valid_until_at", ">", now)
        .get();
      await processInChunks(expiringSnap.docs, 20, async (doc) => {
        const userId = doc.ref.parent.parent?.id;
        if (!userId) return;
        const data = doc.data();
        const merchantId = String(data.merchant_id ?? "");
        const description = String(data.description ?? "votre bon fidélité");
        const validUntil = data.valid_until_at as
          | admin.firestore.Timestamp
          | undefined;
        const daysLeft = validUntil
          ? Math.max(
              0,
              Math.ceil(
                (validUntil.toMillis() - now.toMillis()) /
                  (1000 * 60 * 60 * 24)
              )
            )
          : 0;
        try {
          await db
            .collection("users")
            .doc(userId)
            .collection("notifications")
            .add({
              client_id: userId,
              merchant_id: merchantId,
              merchant_name: "",
              type: "bon_expiring",
              title: "Bon bientôt expiré",
              body: `${description} expire dans ${daysLeft} jour${
                daysLeft > 1 ? "s" : ""
              }.`,
              is_read: false,
              created_at: admin.firestore.FieldValue.serverTimestamp(),
            });
          await doc.ref.update({
            notified_expiring_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          expiringCount++;
        } catch (e) {
          functions.logger.warn("expiring-bon notify failed", {
            userId,
            bonId: doc.id,
            error: e,
          });
        }
      });
    } catch (e) {
      functions.logger.error("expiring bon scan failed", { error: e });
    }

    functions.logger.info("Bon expiration scan complete", {
      expiredCount,
      expiringCount,
    });
    return null;
  });

// ─── 8. Scheduled notifications tick ──────────────────────────────────────────
//
// Counterpart to the immediate quick-send path. Merchants who pick
// "Programmer plus tard" write to merchants/{mid}/scheduled_notifications
// instead of firing the SendMerchantNotification use case directly. This
// pubsub-on-tick CF (every 5 minutes Europe/Paris) promotes pending
// docs whose scheduled_at <= now into sent docs by mirroring the same
// fan-out the existing immediate path does (segment + blocklist filter,
// per-client notification doc write that triggers onNotificationCreated
// for FCM).
//
// Idempotency: each doc carries a status field (pending → sent | failed
// | cancelled) and a transactional update flips pending→processing
// before the fan-out so a concurrent tick can't double-fire it. The
// "processing" intermediate is only kept in-memory for the same
// invocation; persisted final states are sent / failed / cancelled.
//
// Quota: same 5-per-rolling-week cap as immediate sends. If the merchant
// is already at the cap when a scheduled notif fires, the doc is marked
// `failed` with reason `quota_exceeded` rather than dropped — the
// merchant can see why it didn't go out.
//
// Required Firestore index: collection-group scheduled_notifications
// on (status ASC, scheduled_at ASC).
export const processScheduledNotifications = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 540, memory: "512MB" })
  .pubsub.schedule("*/5 * * * *")
  .timeZone("Europe/Paris")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    let processed = 0;
    let failedQuota = 0;

    let pendingSnap: admin.firestore.QuerySnapshot;
    try {
      pendingSnap = await db
        .collectionGroup("scheduled_notifications")
        .where("status", "==", "pending")
        .where("scheduled_at", "<=", now)
        .get();
    } catch (e) {
      functions.logger.error("scheduled-notifs query failed", { error: e });
      return null;
    }

    // Bounded concurrency — 10 docs at a time keeps Firestore reads
    // sane even when the queue is large. Each doc spawns its own
    // followers-list read + per-follower writes; sequential within
    // the chunk is fine, parallel between chunks isn't worth the
    // contention risk on the merchant doc (quota write).
    await processInChunks(pendingSnap.docs, 10, async (doc) => {
      const merchantId = doc.ref.parent.parent?.id;
      if (!merchantId) return;
      const data = doc.data();
      const text: string = (data.text ?? "").toString();
      const audience: string = data.audience ?? "Tous mes clients";
      const rawSegments: unknown = data.segments;
      const segments: string[] = Array.isArray(rawSegments)
        ? rawSegments.filter((s): s is string => typeof s === "string")
        : [];

      try {
        // Atomic claim of the doc — flip status to "processing" and
        // bail out if another tick already grabbed it. Done in a
        // transaction so two concurrent tick invocations cannot both
        // observe pending.
        const claimed = await db.runTransaction<boolean>(async (tx) => {
          const fresh = await tx.get(doc.ref);
          if (!fresh.exists) return false;
          if (fresh.data()?.status !== "pending") return false;
          tx.update(doc.ref, { status: "processing" });
          return true;
        });
        if (!claimed) return;

        // Quota check — same 5/week rolling-window logic the immediate
        // path uses. Read merchant doc, check weekly_notif_sent_count
        // against the reset window. Failing this is a final state.
        const merchantSnap = await db
          .collection("merchants")
          .doc(merchantId)
          .get();
        const merchantData = merchantSnap.data() ?? {};
        const merchantName: string =
          merchantData.name ?? "Votre commerce";
        const weeklyCount: number =
          Number(merchantData.weekly_notif_sent_count ?? 0);
        const resetAt = merchantData.weekly_notif_reset_at;
        const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
        const windowOpen =
          resetAt &&
          (now.toMillis() - resetAt.toMillis()) < sevenDaysMs;
        const overQuota = windowOpen && weeklyCount >= 5;

        if (overQuota) {
          await doc.ref.update({
            status: "failed",
            failure_reason: "quota_exceeded",
            sent_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          failedQuota++;
          return;
        }

        // Resolve eligible followers.
        const followerIds = await getFollowerIds(merchantId);
        if (followerIds.length === 0) {
          await doc.ref.update({
            status: "failed",
            failure_reason: "no_followers",
            sent_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          return;
        }

        // Apply segment filter when audience is "Certains clients".
        let targetIds = followerIds;
        if (audience === "Certains clients" && segments.length > 0) {
          // Hand-rolled equivalent of the Dart segment filter — pulls
          // each loyalty doc and computes the segment via computeSegment
          // (already exported and tested).
          const filtered: string[] = [];
          await processInChunks(targetIds, 32, async (clientId) => {
            try {
              const seg = await getClientSegment(clientId, merchantId);
              if (autoNotificationSegmentMatches(seg, segments)) {
                filtered.push(clientId);
              }
            } catch {
              // Fail-open: a single client lookup error must not
              // exclude the merchant from delivering to others.
            }
          });
          targetIds = filtered;
        }

        // Drop blocked clients (mirrors onPromotionCreated).
        if (targetIds.length > 0) {
          const after: string[] = [];
          await processInChunks(targetIds, 16, async (clientId) => {
            const blocked = await isMerchantBlockedByClient(
              clientId,
              merchantId
            );
            if (!blocked) after.push(clientId);
          });
          targetIds = after;
        }

        if (targetIds.length === 0) {
          await doc.ref.update({
            status: "sent",
            sent_count: 0,
            sent_at: admin.firestore.FieldValue.serverTimestamp(),
          });
          return;
        }

        // Write one notification doc per filtered follower. Same shape
        // as fireAutoNotification's auto/quick-send writes so
        // onNotificationCreated handles the FCM push uniformly.
        let sent = 0;
        await processInChunks(targetIds, 32, async (clientId) => {
          try {
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
                body: text,
                is_read: false,
                created_at:
                  admin.firestore.FieldValue.serverTimestamp(),
              });
            sent++;
          } catch (e) {
            functions.logger.warn("scheduled notif write failed", {
              merchantId,
              clientId,
              error: e,
            });
          }
        });

        // Increment merchant quota counter (same as quick-send path).
        // Uses a transaction so the read-modify-write of the rolling
        // window stays consistent under concurrent ticks.
        await db.runTransaction(async (tx) => {
          const merchantRef = db.collection("merchants").doc(merchantId);
          const fresh = await tx.get(merchantRef);
          const fdata = fresh.data() ?? {};
          const fCount: number =
            Number(fdata.weekly_notif_sent_count ?? 0);
          const fReset = fdata.weekly_notif_reset_at;
          const fWindowOpen =
            fReset &&
            (now.toMillis() - fReset.toMillis()) < sevenDaysMs;
          tx.update(merchantRef, {
            weekly_notif_sent_count: fWindowOpen ? fCount + 1 : 1,
            weekly_notif_reset_at: fWindowOpen
              ? fReset
              : admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        await doc.ref.update({
          status: "sent",
          sent_count: sent,
          sent_at: admin.firestore.FieldValue.serverTimestamp(),
        });
        processed++;
      } catch (e) {
        functions.logger.error("scheduled notif processing failed", {
          merchantId,
          docId: doc.id,
          error: e,
        });
        // Best-effort: leave the doc as `processing` would be confusing
        // — flip back to pending so the next tick retries. If the
        // failure is deterministic the merchant can cancel manually.
        try {
          await doc.ref.update({ status: "pending" });
        } catch {
          /* swallow */
        }
      }
    });

    functions.logger.info("Scheduled notifications tick complete", {
      processed,
      failedQuota,
    });
    return null;
  });

// ─── RGPD: account deletion with cascade ──────────────────────────────────────
//
// `user.delete()` from the client SDK only removes the Firebase Auth account —
// the user's Firestore data (loyalty progress at every merchant they ever
// followed, push tokens, notifications, blocked merchants, AND the merchant
// document if they are a pro) all survive. That violates GDPR's right to
// erasure and gets the app rejected by Apple App Store under guideline 5.1.1
// ("If your app supports account creation, you must also offer account
//  deletion within the app").
//
// This callable handles the full purge in a single privileged path:
//   1. Read users/{uid} to discover dual-profile (merchant_id), followed
//      merchants list, and indexed email / phone.
//   2. For every followed merchant, delete the corresponding loyalty_clients
//      and pending_clients documents (the user's loyalty footprint at
//      that merchant).
//   3. Recursively delete users/{uid} — wipes notifications, push_tokens,
//      followed_merchants, blocked_merchants, and any other subcollection.
//   4. If the user is also a merchant (owns a merchants/{uid} doc),
//      recursively delete that document — wipes loyalty_clients of OTHER
//      users at this merchant, partners, promotions, sent_notifications,
//      auto_notifications. Other clients keep dangling followed_merchants
//      refs that the UI tolerates (getMerchantById returns null for
//      deleted merchants).
//   5. Free the email_index and phone_index entries so the same address
//      can be reused at re-signup.
//   6. Delete the Firebase Auth user.
//
// Idempotent on a best-effort basis — a re-call after a partial failure
// continues cleanup. Cascade errors are logged but do NOT short-circuit
// auth deletion: orphaned docs (no PII surfaced to other users) is a
// far better failure mode than a surviving auth account that locks the
// user out of re-signup.
export const purgeAccount = functions
  .region("europe-west1")
  .runWith({ timeoutSeconds: 300, memory: "512MB" })
  .https.onCall(async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in required to delete account."
      );
    }
    const uid = context.auth.uid;
    functions.logger.info("purgeAccount: starting", { uid });

    // 1) Read user doc to discover merchant_id + indexed contact identifiers.
    let merchantId: string | undefined;
    let lowercaseEmail: string | undefined;
    let phoneId: string | undefined;
    try {
      const userDoc = await db.collection("users").doc(uid).get();
      const data = userDoc.data() ?? {};
      merchantId = (data.merchant_id as string | undefined) || undefined;
      const email = (data.email as string | undefined) || "";
      lowercaseEmail = email ? email.trim().toLowerCase() : undefined;
      phoneId = (data.phone as string | undefined) || undefined;
    } catch (e) {
      functions.logger.warn("purgeAccount: user doc read failed", { uid, error: e });
    }

    // 2) Per-merchant loyalty footprint cleanup.
    let followedMerchantIds: string[] = [];
    try {
      const followedSnap = await db
        .collection("users")
        .doc(uid)
        .collection("followed_merchants")
        .get();
      followedMerchantIds = followedSnap.docs.map((d) => d.id);
    } catch (e) {
      functions.logger.warn("purgeAccount: followed list read failed", {
        uid,
        error: e,
      });
    }

    await processInChunks(followedMerchantIds, 8, async (mid) => {
      try {
        await db
          .collection("merchants")
          .doc(mid)
          .collection("loyalty_clients")
          .doc(uid)
          .delete();
      } catch (e) {
        functions.logger.warn("purgeAccount: loyalty_clients delete failed", {
          uid,
          mid,
          error: e,
        });
      }
      try {
        await db
          .collection("merchants")
          .doc(mid)
          .collection("pending_clients")
          .doc(uid)
          .delete();
      } catch (e) {
        functions.logger.warn("purgeAccount: pending_clients delete failed", {
          uid,
          mid,
          error: e,
        });
      }
    });

    // 3) Recursively delete the user's own root document and every
    //    subcollection beneath it.
    try {
      await db.recursiveDelete(db.collection("users").doc(uid));
    } catch (e) {
      functions.logger.error("purgeAccount: recursiveDelete users failed", {
        uid,
        error: e,
      });
    }

    // 4) If the user is also a merchant, wipe their merchant footprint too.
    if (merchantId) {
      try {
        await db.recursiveDelete(db.collection("merchants").doc(merchantId));
      } catch (e) {
        functions.logger.error(
          "purgeAccount: recursiveDelete merchants failed",
          { uid, merchantId, error: e }
        );
      }
    }

    // 5) Free index entries so the email / phone can be reused at re-signup.
    if (lowercaseEmail) {
      try {
        await db.collection("email_index").doc(lowercaseEmail).delete();
      } catch (e) {
        functions.logger.warn("purgeAccount: email_index delete failed", {
          uid,
          lowercaseEmail,
          error: e,
        });
      }
    }
    if (phoneId) {
      try {
        await db.collection("phone_index").doc(phoneId).delete();
      } catch (e) {
        functions.logger.warn("purgeAccount: phone_index delete failed", {
          uid,
          phoneId,
          error: e,
        });
      }
    }

    // 6) Finally drop the auth account so the user cannot sign in any more.
    try {
      await admin.auth().deleteUser(uid);
    } catch (e: unknown) {
      // If the auth user no longer exists (a mid-failed previous run, or
      // Firebase Auth removed it via console), treat as success — the
      // Firestore footprint is the part that matters for GDPR.
      const code = (e as { code?: string })?.code;
      if (code !== "auth/user-not-found") {
        functions.logger.error("purgeAccount: auth deleteUser failed", {
          uid,
          error: e,
        });
        throw new functions.https.HttpsError(
          "internal",
          "Auth deletion failed; please retry."
        );
      }
    }

    functions.logger.info("purgeAccount: completed", {
      uid,
      merchantId: merchantId ?? null,
      followedCount: followedMerchantIds.length,
    });
    return { ok: true };
  });
