const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { logger } = require("firebase-functions/v2");

initializeApp();
const db = getFirestore();

exports.sendNotification = onDocumentCreated(
  {
    document: "notifications/{docId}",
    region: "us-central1",
    timeoutSeconds: 300,
  },
  async (event) => {
    const docId = event.params.docId;
    const data = event.data.data();
    const docRef = db.doc(`notifications/${docId}`);

    logger.info(`📨 Processing notification ${docId}`, { data });

    if (data.processed) {
      logger.info(`🔁 Already processed, skipping`);
      return null;
    }

    const token = data.to;
    const userId = data.userId;

    if (!token || typeof token !== "string") {
      logger.error(`❌ Missing or invalid FCM token`);
      await docRef.update({
        processed: true,
        failed: true,
        error: "Missing or invalid FCM token",
        processedAt: FieldValue.serverTimestamp(),
      });
      return null;
    }

    // 🔎 Fetch patient's name
    let fullName = "a patient";
    if (userId) {
      try {
        const userSnap = await db.collection("users").doc(userId).get();
        if (userSnap.exists) {
          const userData = userSnap.data();
          const firstName = userData.firstName || "";
          const lastName = userData.lastName || "";
          fullName = `${firstName} ${lastName}`.trim();
        } else {
          logger.warn(`⚠️ No user found for userId: ${userId}`);
        }
      } catch (e) {
        logger.warn(`⚠️ Could not fetch patient name: ${e.message}`);
      }
    }

    // 🔧 Build payload
    const notificationBody =
      typeof data.body === "string" && data.body.trim().length > 0
        ? data.body
        : `You have a new appointment request from ${fullName}`;

    const payload = {
      notification: {
        title: data.title || "New Appointment",
        body: notificationBody,
      },
      data: data.data || {},
      token,
    };

    logger.info(`👤 Full name resolved: ${fullName}`);
    logger.info(`📨 Notification body: ${notificationBody}`);

    // ✅ Send notification
    try {
      const response = await getMessaging().send(payload);
      logger.info(`✅ Notification sent: ${response}`);

      await docRef.update({
        processed: true,
        failed: false,
        processedAt: FieldValue.serverTimestamp(),
        messageId: response,
      });
    } catch (error) {
      logger.error(`❌ Error sending notification: ${error.message}`);
      await docRef.update({
        processed: true,
        failed: true,
        error: error.message,
        processedAt: FieldValue.serverTimestamp(),
      });
    }
  }
);
