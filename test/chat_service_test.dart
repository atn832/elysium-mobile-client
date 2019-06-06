import 'package:elysium/chatservice.dart';
import 'package:flutter_test/flutter_test.dart';

import 'firebase_auth_mocks.dart';
import 'firebase_mocks.dart';

final now = DateTime(2019, 06, 06);

void main() {
  test('returns messages', () async {
    final firebase = MockFirestoreInstance();
    await firebase.collection('messages').add({
      'content': 'hello!',
      'timestamp': now,
    });
    final service =
        ChatService.withParameters(firebase, MockFirebaseAuth(), now);
    final messages = await service.getMessages().first;
    expect(messages, equals(['hello!']));
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
    expect(users[0].name, equals('Bob'));
  });
}
