import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const userIdsPromise: Promise<string[]> = admin.firestore().collection('/users').get().then((snapshot) => {
	return snapshot.docs.map((docSnapshot) => {
		return docSnapshot.id;
	});
});

export const notifyOnNewMessage = functions.firestore.document('/messages/{messageId}')
	.onCreate(async (snapshot, context) => {
		if (!snapshot) return;

		console.log(context.params.messageId);
		console.log(snapshot.data);

		const notificationContent = {
			notification: {
				title: 'Nouveau message',
				body: snapshot.get('content'),
				icon: 'default'
			}
		};
		const userIds = await userIdsPromise;
		return Promise.all(userIds.map((userId) => {
			// Do not notify self.
			if (userId === snapshot.get('uid')) return;

			// Notify others.
			return admin.messaging().sendToTopic(userId, notificationContent).then(result => {
				console.log(`Notification sent to ${userId}`);
			});
		}));
	});
