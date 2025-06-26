const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendScheduledNotifications = functions.pubsub
  .schedule("every 1 minutes").onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    const snapshot = await admin.firestore().collection("tasks")
      .where("startTime", "<=", now)
      .where("isSent", "==", false)
      .get();

    if (snapshot.empty) {
      console.log("✅ No tasks to notify at this time.");
      return null;
    }

    const promises = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      const token = data.token;

      if (!token) return;

      const message = {
        token,
        notification: {
          title: "⏰ Task Reminder",
          body: data.title || "You have a task scheduled now.",
        },
        android: {
          priority: "high",
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      };

      const p = admin.messaging().send(message)
        .then(() => {
          console.log("📬 Sent to:", token);
          return doc.ref.update({ isSent: true });
        })
        .catch((err) => {
          console.error("❌ Failed to send to token:", token, err);
        });

      promises.push(p);
    });

    await Promise.all(promises);
    return null;
  });
