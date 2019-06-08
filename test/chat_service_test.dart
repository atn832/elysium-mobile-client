import 'package:elysium/chatservice.dart';
import 'package:flutter_test/flutter_test.dart';

import 'firebase_auth_mocks.dart';
import 'firebase_mocks.dart';

final now = DateTime(2019, 06, 06);

final expectedStateAfterSend = """{
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
    await firebase.collection('messages').add({
      'content': 'hello!',
      'uid': 'z',
      'timestamp': now,
    });
    await firebase.collection('users').add({
      'name': 'Bob',
      'timezone': 'Europe/London',
    });
    final service =
        ChatService.withParameters(firebase, MockFirebaseAuth(), now);
    final messages = await service.getMessages().first;
    expect(messages, equals(['Bob: hello!']));
  });

  test('returns users', () async {
    final firebase = MockFirestoreInstance();
    await firebase.collection('users').add({
      'name': 'Bob',
      'timezone': 'Europe/London',
    });
    final service =
        ChatService.withParameters(firebase, MockFirebaseAuth(), now);
    final users = await service.getUsers().first;
    expect(users.length, equals(1));
    expect(users[0].uid, equals('z'));
    expect(users[0].name, equals('Bob'));

    final userMap = await service.getUserMap().first;
    expect(userMap.length, equals(1));
    expect(userMap['z'].name, equals('Bob'));
  });

  test('sends messages', () async {
    final firebase = MockFirestoreInstance();
    final auth = MockFirebaseAuth(signedIn: true);
    final service = ChatService.withParameters(firebase, auth, now);
    await service.sendMessage('yes', now);
    expect(firebase.dump(), equals(expectedStateAfterSend));
  });
}
