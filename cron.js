// cron.js
const admin = require('firebase-admin');
const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
  credential: admin.credential.cert(serviceAccount),
});


const db = getFirestore();
const messaging = getMessaging();

async function sendNotifications() {
  const now = new Date();
  const snapshot = await db.collection('tasks')
    .where('startTime', '<=', now)
    .where('isSent', '==', false)
    .get();

  if (snapshot.empty) {
    console.log("✅ No tasks to send");
    return;
  }

  for (const doc of snapshot.docs) {
    const task = doc.data();
    if (!task.token) continue;

    try {
      await messaging.send({
        token: task.token,
        notification: {
          title: "⏰ Task Reminder",
          body: task.title || "Your task is due now.",
        },
      });
      await doc.ref.update({ isSent: true });
      console.log("✅ Notification sent for:", task.title);
    } catch (err) {
      console.error("❌ FCM error:", err);
    }
  }
}

sendNotifications();
