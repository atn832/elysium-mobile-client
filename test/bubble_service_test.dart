import 'package:elysium/bubble_service.dart';
import 'package:elysium/message.dart';
import 'package:elysium/user.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2019, 06, 06);

void main() {
  test('makes bubbles', () {
    expect(BubbleService.getBubbles(null), equals([]));

    final user1 = User()..uid = 'b';
    final user2 = User()..uid = 'c';
    final messages = [
      Message()
        ..author = user1
        ..message = 'hello Curtis'
        ..time = now,
      Message()
        ..author = user2
        ..message = 'hello Brian'
        ..time = now,
      Message()
        ..author = user2
        ..message = 'how are you?'
        ..time = now,
      Message()
        ..author = user2
        ..message = 'gotta go!'
        ..time = now.add(Duration(minutes: 10)),
    ];
    final bubbles = BubbleService.getBubbles(messages);
    expect(bubbles.length, equals(3));
  });
}
