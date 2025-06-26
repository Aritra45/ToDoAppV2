import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

const serviceAccount = JSON.parse(process.env.FIREBASE_CREDENTIALS || '{}');

const app = initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore(app);
const messaging = getMessaging(app);

export default async function handler(req, res) {
  try {
    const now = new Date();

    const snap = await db
      .collection('scheduled_notifications')
      .where('scheduledTime', '<=', now)
      .where('isSent', '==', false)
      .get();

    if (snap.empty) {
      return res.status(200).json({ message: 'No notifications to send.' });
    }

    const sends = snap.docs.map(async doc => {
      const { token, title = 'Task Reminder' } = doc.data();
      const msg = {
        token,
        notification: {
          title: '⏰ Task Reminder',
          body: title,
        },
      };

      await messaging.send(msg);
      await doc.ref.update({ isSent: true, sentAt: new Date() });
    });

    await Promise.all(sends);
    res.status(200).json({ message: `📨 Sent ${sends.length} notifications.` });
  } catch (error) {
    console.error('Notification error:', error);
    res.status(500).json({ error: 'Failed to send notifications.' });
  }
}
