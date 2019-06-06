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
    await Future.delayed(Duration(seconds: 1), () {});
    expect(messages, equals(['hello!']));
  });
}
