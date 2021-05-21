import 'package:elysium/bubble_service.dart';
import 'package:elysium/message.dart';
import 'package:elysium/position.dart';
import 'package:elysium/user.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2019, 06, 06);

void main() {
  final user1 = User()..uid = 'b';
  final user2 = User()..uid = 'c';
  test('makes bubbles', () {
    expect(BubbleService.getBubbles(null), equals([]));
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

  test('surfaces position', () {
    final messages = [
      Message()
        ..author = user1
        ..message = 'hello'
        ..time = now
        ..position = Position(latitude: 10, longitude: 100)
    ];
    final bubbles = BubbleService.getBubbles(messages);
    expect(bubbles.length, equals(1));
    expect(
        bubbles.last.position, equals(Position(latitude: 10, longitude: 100)));

    // Should ignore null positions.
    messages.add(Message()
      ..author = user1
      ..message = 'hello'
      ..time = now);
    final bubbles2 = BubbleService.getBubbles(messages);
    expect(bubbles2.length, equals(1));
    expect(
        bubbles2.last.position, equals(Position(latitude: 10, longitude: 100)));

    // Should update newer positions.
    messages.add(Message()
      ..author = user1
      ..message = 'hello'
      ..time = now
      ..position = Position(latitude: 20, longitude: 100));
    final bubbles3 = BubbleService.getBubbles(messages);
    expect(bubbles3.length, equals(1));
    expect(
        bubbles3.last.position, equals(Position(latitude: 20, longitude: 100)));
  });
}
