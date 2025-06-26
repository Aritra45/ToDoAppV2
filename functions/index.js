const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

exports.sendScheduledNotifications = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async () => {
    const now = new Date();
    const querySnapshot = await db
      .collection('scheduled_notifications')
      .where('scheduledTime', '<=', now)
      .where('isSent', '==', false)
      .get();

    const sendPromises = [];

    querySnapshot.forEach(doc => {
      const data = doc.data();
      const token = data.token;
      const title = data.title ?? 'Reminder';

      const message = {
        token,
        notification: {
          title: '⏰ Task Reminder',
          body: title,
        },
      };

      sendPromises.push(
        admin.messaging().send(message).then(() => {
          return doc.ref.update({ isSent: true, sentAt: new Date() });
        }).catch(err => {
          console.error(`Failed to send notification to ${token}:`, err);
        })
      );
    });

    await Promise.all(sendPromises);
    console.log(`✅ Processed ${sendPromises.length} notifications.`);
  });
