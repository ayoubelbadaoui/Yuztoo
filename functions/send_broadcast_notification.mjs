/**
 * Broadcast a single notification to every user in Firestore.
 * The onNotificationCreated Cloud Function handles FCM delivery automatically.
 *
 * Usage:
 *   node tools/send_broadcast_notification.mjs
 *
 * Credentials: uses Application Default Credentials (ADC).
 * Run `firebase login` or `gcloud auth application-default login` beforehand.
 */

import { initializeApp, cert, applicationDefault } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { randomUUID } from "crypto";

// ── Configuration ────────────────────────────────────────────────────────────
const PROJECT_ID = "yuztoo";
const NOTIFICATION = {
  type: "auto",           // routes to Notifications tab in the app
  title: "test iphone",
  body: "Test push notification",
  merchant_id: null,
  merchant_name: null,
  promotion_id: null,
};
const BATCH_SIZE = 400;   // Firestore limit is 500 writes per batch
// ────────────────────────────────────────────────────────────────────────────

initializeApp({ credential: applicationDefault(), projectId: PROJECT_ID });
const db = getFirestore();

async function main() {
  console.log(`[broadcast] Fetching all users from project "${PROJECT_ID}"…`);

  // Page through all user documents
  const userIds = [];
  let query = db.collection("users").select().limit(500);
  let lastDoc = null;

  while (true) {
    const snap = lastDoc
      ? await query.startAfter(lastDoc).get()
      : await query.get();
    if (snap.empty) break;
    snap.docs.forEach((d) => userIds.push(d.id));
    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.size < 500) break;
  }

  console.log(`[broadcast] Found ${userIds.length} users. Writing notifications…`);

  let sent = 0;
  let failed = 0;

  // Process in batches
  for (let i = 0; i < userIds.length; i += BATCH_SIZE) {
    const chunk = userIds.slice(i, i + BATCH_SIZE);
    const batch = db.batch();

    for (const uid of chunk) {
      const notifRef = db
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .doc(randomUUID());

      batch.set(notifRef, {
        ...NOTIFICATION,
        is_read: false,
        created_at: Timestamp.now(),
      });
    }

    try {
      await batch.commit();
      sent += chunk.length;
      console.log(`[broadcast] ✓ ${sent}/${userIds.length} notifications written`);
    } catch (err) {
      failed += chunk.length;
      console.error(`[broadcast] ✗ batch error:`, err.message);
    }
  }

  console.log(
    `\n[broadcast] Done. sent=${sent}, failed=${failed}, total=${userIds.length}`
  );
}

main().catch((err) => {
  console.error("[broadcast] Fatal error:", err);
  process.exit(1);
});
