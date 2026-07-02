/**
 * One-off admin script: re-send FCM alerts for every `awaiting` passage session.
 *
 * Usage:
 *   cd functions && node scripts/send_pending_passage_test_pushes.mjs          # dry-run
 *   cd functions && node scripts/send_pending_passage_test_pushes.mjs --send  # deliver
 */
import { createRequire } from "module";
const require = createRequire(import.meta.url);
const admin = require("firebase-admin");

const SEND = process.argv.includes("--send");
const TEST_PREFIX = "[TEST] ";

admin.initializeApp({ projectId: "yuztoo" });
const db = admin.firestore();
const messaging = admin.messaging();

async function getUserDeviceFcmToken(userId) {
  if (!userId) return null;
  const snap = await db
    .collection("users")
    .doc(userId)
    .collection("push_tokens")
    .doc("device")
    .get();
  const token = snap.data()?.fcm_token;
  return typeof token === "string" && token.trim() ? token.trim() : null;
}

async function sendHighPriorityAlertPush(token, title, body, data) {
  await messaging.send({
    token,
    notification: { title, body },
    data,
    android: {
      priority: "high",
      notification: {
        channelId: "yuztoo_promo_v2",
        priority: "high",
        defaultSound: true,
      },
    },
    apns: {
      headers: { "apns-priority": "10", "apns-push-type": "alert" },
      payload: { aps: { sound: "default", "content-available": 1 } },
    },
  });
}

function resolveMerchantPublicName(data) {
  if (!data) return "Votre commerce";
  const display = data.display_name ?? data.commercial_name ?? data.name;
  return typeof display === "string" && display.trim()
    ? display.trim()
    : "Votre commerce";
}

async function main() {
  console.log(SEND ? "Mode: SEND" : "Mode: DRY-RUN (pass --send to deliver)");

  const snap = await db
    .collectionGroup("active_validations")
    .where("status", "==", "awaiting")
    .get();

  if (snap.empty) {
    console.log("No awaiting passage sessions found.");
    return;
  }

  console.log(`Found ${snap.size} awaiting session(s).\n`);

  let merchantSent = 0;
  let merchantSkipped = 0;
  let clientSent = 0;
  let clientSkipped = 0;

  for (const doc of snap.docs) {
    const merchantId = doc.ref.parent.parent?.id ?? "?";
    const clientUid = doc.id;
    const data = doc.data();
    const clientName = data.client_display_name ?? "Un client";

    const merchantSnap = await db.collection("merchants").doc(merchantId).get();
    const merchantData = merchantSnap.data();
    const ownerUid = merchantData?.owner_uid;
    const merchantName = resolveMerchantPublicName(merchantData);

    console.log(`— merchant=${merchantId} client=${clientUid} (${clientName})`);

    if (!ownerUid) {
      console.log("  merchant: SKIP (no owner_uid)");
      merchantSkipped++;
    } else {
      const token = await getUserDeviceFcmToken(ownerUid);
      if (!token) {
        console.log(`  merchant: SKIP (no FCM token for owner ${ownerUid})`);
        merchantSkipped++;
      } else if (SEND) {
        await sendHighPriorityAlertPush(
          token,
          `${TEST_PREFIX}Passage à valider`,
          `${clientName} attend votre validation`,
          {
            type: "loyalty_passage_request",
            merchant_id: merchantId,
            client_uid: clientUid,
            client_name: clientName,
          }
        );
        console.log(`  merchant: SENT → owner ${ownerUid}`);
        merchantSent++;
      } else {
        console.log(`  merchant: would send → owner ${ownerUid}`);
        merchantSent++;
      }
    }

    const clientToken = await getUserDeviceFcmToken(clientUid);
    if (!clientToken) {
      console.log(`  client: SKIP (no FCM token)`);
      clientSkipped++;
    } else if (SEND) {
      await db
        .collection("users")
        .doc(clientUid)
        .collection("notifications")
        .add({
          client_id: clientUid,
          merchant_id: merchantId,
          merchant_name: merchantName,
          type: "loyalty",
          title: `${TEST_PREFIX}Validation en cours chez ${merchantName}`,
          body:
            "Votre passage est en attente de validation par le commerçant.",
          is_read: false,
          created_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      console.log(`  client: inbox written (FCM via onNotificationCreated)`);
      clientSent++;
    } else {
      console.log(`  client: would write inbox + FCM`);
      clientSent++;
    }

    console.log("");
  }

  console.log("Summary:");
  console.log(`  merchant pushes: ${merchantSent} ${SEND ? "sent" : "would send"}, ${merchantSkipped} skipped`);
  console.log(`  client alerts:   ${clientSent} ${SEND ? "sent" : "would send"}, ${clientSkipped} skipped`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
