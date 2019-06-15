import 'dart:async';
import 'dart:typed_data';

import 'package:elysium/bubble.dart';
import 'package:elysium/bubble_widget.dart';
import 'package:elysium/chatservice.dart';
import 'package:elysium/message.dart';
import 'package:elysium/message_widget.dart';
import 'package:elysium/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/mockito.dart';

final now = DateTime(2019, 06, 06);

void main() {
  testWidgets('displays bubbles', (WidgetTester tester) async {
    final user = User()..name = 'Bob';
    final m = Message()
      ..author = user
      ..message = 'hello!'
      ..time = now;
    final b = Bubble()
      ..author = user
      ..messages = [m];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BubbleWidget(b))));
    await tester.pump();
    expect(find.text('B'), findsOneWidget);
    expect(find.text('hello!'), findsOneWidget);
    expect(find.text('jeudi 6 juin 2019 00:00'), findsOneWidget);
  });
}

class MockImageFactory extends Mock implements ImageFactory {}

class MockChatService extends Mock implements ChatService {}
