import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_mocks/cloud_firestore_mocks.dart';
import 'package:elysium/chatservice.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2019, 06, 06);

final expectedStateAfterSend = """{
  "users": {
    "aabbcc": {
      "name": "Bob",
      "timezone": "Europe/London",
      "lastTalked": "2019-06-06T00:00:00.000"
    }
  },
  "messages": {
    "z": {
      "uid": "aabbcc",
      "content": "yes",
      "timestamp": "2019-06-06T00:00:00.000"
    }
  }
}""";

void main() {
  test('returns messages', () async {
    final firebase = MockFirestoreInstance();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = (await auth.currentUser()).uid;
    await firebase.collection('messages').add({
      'content': 'hello!',
      'uid': uid,
      'timestamp': now,
    });
    await firebase.collection('users').document(uid).setData({
      'name': 'Bob',
    });
    final service =
        ChatService.withParameters(firebase, auth, MockFirebaseStorage(), now);
    final messages = await service.getMessages().first;
    expect(messages.length, equals(1));
    expect(messages[0].author.name, equals('Bob'));
    expect(messages[0].message, equals('hello!'));
    expect(messages[0].time, equals(now));
  });

  test('returns users', () async {
    final firebase = MockFirestoreInstance();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = (await auth.currentUser()).uid;
    await firebase.collection('users').document(uid).setData({
      'name': 'Bob',
      'timezone': 'Europe/London',
    });
    final service =
        ChatService.withParameters(firebase, auth, MockFirebaseStorage(), now);
    final users = await service.getUsers().first;
    expect(users.length, equals(1));
    expect(users[0].uid, equals(uid));
    expect(users[0].name, equals('Bob'));

    final userMap = await service.getUserMap().first;
    expect(userMap.length, equals(1));
    expect(userMap[uid].name, equals('Bob'));
  });

  test('sends messages', () async {
    final firebase = MockFirestoreInstance();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = (await auth.currentUser()).uid;
    await firebase.collection('users').document(uid).setData({
      'name': 'Bob',
      'timezone': 'Europe/London',
    });
    final service =
        ChatService.withParameters(firebase, auth, MockFirebaseStorage(), now);
    await service.sendMessage('yes', now);
    expect(firebase.dump(), equals(expectedStateAfterSend));
  });

  test('listens to messages from last talked', () async {
    final firebase = MockFirestoreInstance();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = (await auth.currentUser()).uid;
    await firebase.collection('messages').add({
      'content': 'hello!',
      'uid': uid,
      'timestamp': now.subtract(Duration(minutes: 3)),
    });
    await firebase.collection('messages').add({
      'content': 'newer',
      'uid': uid,
      'timestamp': now,
    });
    await firebase.collection('users').document(uid).setData({
      'name': 'Bob',
      'timezone': 'Europe/London',
      'lastTalked': Timestamp.fromDate(now),
    });
    final service =
        ChatService.withParameters(firebase, auth, MockFirebaseStorage(), now);
    final messages = await service.getMessages().first;
    expect(messages[0].message, equals('newer'));
  });

  test('sends images', () async {
    final firebase = MockFirestoreInstance();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = (await auth.currentUser()).uid;
    await firebase.collection('users').document(uid).setData({
      'name': 'Bob',
      'timezone': 'Europe/London',
      'lastTalked': Timestamp.fromDate(now),
    });
    final storage = MockFirebaseStorage();
    final service = ChatService.withParameters(firebase, auth, storage, now);
    final image =
        File('/storage/emulated/0/DCIM/Camera/IMG_20190609_144619.jpg');
    await service.sendImage(image);

    // Check that the gs:// link was sent.
    final messages = await service.getMessages().first;
    expect(messages[0].message,
        equals('gs://some-bucket//IMG_20190609_144619.jpg'));
    // Verify that the image was put.
    final fileRef = (storage.ref().child('IMG_20190609_144619.jpg'))
        as MockStorageReference;
    expect(fileRef.storedFile, equals(image));
  });
}
