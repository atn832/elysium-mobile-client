import 'package:elysium/chatservice.dart';
import 'package:elysium/message_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  testWidgets('clears message after sending', (WidgetTester tester) async {
    final chatService = MockChatService();
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MessageInput(chatService))));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'yes');
    expect(find.text('yes'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.send));
    verify(chatService.sendMessage('yes'));
    expect(find.text('yes'), findsNothing);
  });
}

class MockChatService extends Mock implements ChatService {}
