import 'bubble.dart';
import 'message.dart';

const NewBubbleThreshold = Duration(minutes: 5);

class BubbleService {
  static List<Bubble> getBubbles(List<Message>? messages) {
    if (messages == null) return [];

    final bubbles = <Bubble>[];
    for (final message in messages) {
      final newBubble = shouldCreateBubble(bubbles, message);
      if (newBubble) {
        bubbles.add(Bubble()
          ..author = message.author
          ..messages = [message]);
      } else {
        bubbles.last.messages.add(message);
      }
      // Update the position if present.
      // Make the bubble use the first message's position to prevent flickering.
      if (message.position != null && bubbles.last.position == null) {
        bubbles.last.position = message.position;
      }
    }
    return bubbles;
  }

  static bool shouldCreateBubble(List<Bubble> bubbles, Message message) =>
      bubbles.isEmpty ||
      bubbles.last.author.uid != message.author.uid ||
      message.time.difference(bubbles.last.messages.last.time) >
          NewBubbleThreshold;
}
