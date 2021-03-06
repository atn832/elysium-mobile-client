import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elysium/chatservice.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';

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
    final firebase = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = auth.currentUser!.uid;
    await firebase.collection('messages').add({
      'content': 'hello!',
      'uid': uid,
      'timestamp': now,
    });
    await firebase.collection('users').doc(uid).set({
      'name': 'Bob',
    });
    final service = ChatService.withParameters(
        firebase, auth, MockFirebaseStorage(), null, null, now);
    final messages = await service.getMessages().first;
    expect(messages.length, equals(1));
    expect(messages[0].author.name, equals('Bob'));
    expect(messages[0].message, equals('hello!'));
    expect(messages[0].time, equals(now));
  });

  test('returns users', () async {
    final firebase = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = auth.currentUser!.uid;
    await firebase.collection('users').doc(uid).set({
      'name': 'Bob',
      'timezone': 'Europe/London',
    });
    final service = ChatService.withParameters(
        firebase, auth, MockFirebaseStorage(), null, null, now);
    final users = await service.getUsers().first;
    expect(users.length, equals(1));
    expect(users[0].uid, equals(uid));
    expect(users[0].name, equals('Bob'));

    final userMap = await service.getUserMap().first;
    expect(userMap.length, equals(1));
    expect(userMap[uid]!.name, equals('Bob'));
  });

  test('sends messages', () async {
    final firebase = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = auth.currentUser!.uid;
    await firebase.collection('users').doc(uid).set({
      'name': 'Bob',
      'timezone': 'Europe/London',
    });
    final service = ChatService.withParameters(
        firebase, auth, MockFirebaseStorage(), null, null, now);
    await service.sendMessage('yes', now);
    expect(firebase.dump(), equals(expectedStateAfterSend));
  });

  test('sends location', () async {
    final firebase = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = auth.currentUser!.uid;
    await firebase.collection('users').doc(uid).set({
      'name': 'Bob',
      'timezone': 'Europe/London',
    });
    final geolocator = new MockGeolocator();

    positionStream() async* {
      yield Position(
          latitude: 30,
          longitude: 100,
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          timestamp: null);
    }

    when(Geolocator.getPositionStream()).thenAnswer((_) {
      return positionStream();
    });
    final service = ChatService.withParameters(
        firebase, auth, MockFirebaseStorage(), geolocator, null, now);
    await Future.delayed(Duration(milliseconds: 1));
    await service.sendMessage('i am here', now);
    final messages = await firebase.collection('messages').get();
    final message = messages.docs.first;
    expect(message['location'], equals(GeoPoint(30, 100)));
  });

  test('updates user on send messages', () async {
    final firebase = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = auth.currentUser!.uid;
    await firebase.collection('users').doc(uid).set({
      'name': 'Bob',
      'timezone': 'Europe/London',
    });
    getTimezone() {
      return Future.value('Asia/Taipei');
    }

    final service = ChatService.withParameters(
        firebase, auth, MockFirebaseStorage(), null, getTimezone, now);
    await service.sendMessage('yes', now);
    final user = await firebase.collection('users').doc(uid).get();
    expect(user['timezone'], equals('Asia/Taipei'));
    expect(user['lastTalked'], equals(Timestamp.fromDate(now)));
  });

  test('listens to messages from last talked', () async {
    final firebase = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = auth.currentUser!.uid;
    await firebase.collection('messages').add({
      'content': 'hello!',
      'uid': uid,
      'timestamp': now.subtract(Duration(hours: 3)),
    });
    await firebase.collection('messages').add({
      'content': 'newer',
      'uid': uid,
      'timestamp': now,
    });
    await firebase.collection('users').doc(uid).set({
      'name': 'Bob',
      'timezone': 'Europe/London',
      'lastTalked': Timestamp.fromDate(now),
    });
    final service = ChatService.withParameters(
        firebase, auth, MockFirebaseStorage(), null, null, now);
    final messages = await service.getMessages().first;
    expect(messages[0].message, equals('newer'));
  });

  test('sends images', () async {
    final firebase = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = auth.currentUser!.uid;
    await firebase.collection('users').doc(uid).set({
      'name': 'Bob',
      'timezone': 'Europe/London',
      'lastTalked': Timestamp.fromDate(now),
    });
    final storage = MockFirebaseStorage();
    final service =
        ChatService.withParameters(firebase, auth, storage, null, null, now);
    final image =
        File('/storage/emulated/0/DCIM/Camera/IMG_20190609_144619.jpg');
    await service.sendImage(image);

    // Check that the gs:// link was sent.
    final messages = await service.getMessages().first;
    expect(messages[0].message,
        equals('gs://some-bucket//IMG_20190609_144619.jpg'));
    // Verify that the image was put.
    final fileRef = storage.ref().child('IMG_20190609_144619.jpg');
    // expect(fileRef.getData(), equals(image));
  });

  test('getMore gets more messages', () async {
    final firebase = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth(signedIn: true);
    final uid = auth.currentUser!.uid;
    await firebase.collection('messages').add({
      'content': 'older',
      'uid': uid,
      'timestamp': now.subtract(Duration(hours: 3)),
    });
    await firebase.collection('messages').add({
      'content': 'newer',
      'uid': uid,
      'timestamp': now,
    });
    await firebase.collection('users').doc(uid).set({
      'name': 'Bob',
      'timezone': 'Europe/London',
      'lastTalked': Timestamp.fromDate(now),
    });
    final service = ChatService.withParameters(
        firebase, auth, MockFirebaseStorage(), null, null, now);
    // Expect one, then two messages upon calling getMoreMessages.
    expect(service.getMessages(), emitsInOrder([hasLength(1), hasLength(2)]));
    service.getMoreMessages();
  });
}

class MockGeolocator extends Mock implements Geolocator {}
