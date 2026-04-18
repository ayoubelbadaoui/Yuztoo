import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Triggered when a new ClientNotification document is created at
 * users/{userId}/notifications/{notificationId}.
 *
 * Reads the FCM token from users/{userId}/push_tokens/device,
 * then sends a data + notification push to the device.
 */
export const onNotificationCreated = functions
  .region("europe-west1")
  .firestore.document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const data = snap.data();

    if (!data) {
      functions.logger.warn("onNotificationCreated: empty document", { userId });
      return null;
    }

    // --- 1. Fetch device FCM token ---
    const tokenDoc = await db
      .collection("users")
      .doc(userId)
      .collection("push_tokens")
      .doc("device")
      .get();

    if (!tokenDoc.exists) {
      functions.logger.info("onNotificationCreated: no FCM token for user", { userId });
      return null;
    }

    const fcmToken: string | undefined = tokenDoc.data()?.fcm_token;
    if (!fcmToken) {
      functions.logger.info("onNotificationCreated: fcm_token field missing", { userId });
      return null;
    }

    // --- 2. Build the message ---
    const title: string = data.title ?? "Yuztoo";
    const body: string = data.body ?? "";
    const notificationId: string = snap.id;
    const promotionId: string | undefined = data.promotion_id;
    const merchantId: string | undefined = data.merchant_id;

    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      // Data payload lets the app handle tap → navigate to the right screen.
      data: {
        notification_id: notificationId,
        type: data.type ?? "promotion",
        ...(promotionId ? { promotion_id: promotionId } : {}),
        ...(merchantId ? { merchant_id: merchantId } : {}),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "yuztoo_promotions",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    // --- 3. Send ---
    try {
      const response = await messaging.send(message);
      functions.logger.info("Push sent", { userId, notificationId, response });
    } catch (error: any) {
      // Token is invalid/expired → clean it up so we don't retry forever.
      if (
        error?.errorInfo?.code === "messaging/registration-token-not-registered" ||
        error?.errorInfo?.code === "messaging/invalid-registration-token"
      ) {
        functions.logger.warn("Stale FCM token, deleting", { userId });
        await tokenDoc.ref.delete();
      } else {
        functions.logger.error("Failed to send push", { userId, error });
      }
    }

    return null;
  });
