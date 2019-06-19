import 'dart:async';

import 'package:elysium/chatservice.dart';
import 'package:elysium/chatview.dart';
import 'package:elysium/message.dart';
import 'package:elysium/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/mockito.dart';

const platform = const MethodChannel('app.channel.shared.data');

void main() {
  testWidgets('sends shared text', (WidgetTester tester) async {
    platform.setMockMethodCallHandler((_) {
      return Future.value('http://www.google.com');
    });

    final chatService = MockChatService();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ChatView.withParameters(chatService))));

    await tester.pump(Duration(seconds: 5));

    verify(chatService.sendMessage('http://www.google.com'));
  });
}

class MockChatService extends Mock implements ChatService {
  Stream<List<Message>> getMessages() {
    return Stream.fromIterable([
      [
        Message()
          ..author = (User()..name = 'Bob')
          ..message = 'hello!'
          ..time = DateTime.now().subtract(Duration(hours: 1))
      ],
    ]);
  }
}
