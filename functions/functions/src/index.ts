import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const notifyOnNewMessage = functions.firestore.document('/messages/{messageId}')
	.onCreate((snapshot, context) => {
		if (snapshot == null) return;

		console.log(context.params.messageId);
		console.log(snapshot.data);

		const notificationContent = {
			notification: {
				title: 'Nouveau message',
				body: snapshot.get('content'),
				icon: "default"
			}
		};
		return admin.messaging().sendToTopic('all', notificationContent).then(result => {
			console.log('Notification sent!');
		});
	});
