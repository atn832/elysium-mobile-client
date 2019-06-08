import 'dart:async';

import 'package:elysium/chatservice.dart';
import 'package:elysium/chatview.dart';
import 'package:elysium/message_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elysium/main.dart';
import 'package:mockito/mockito.dart';

import 'firebase_auth_mocks.dart';

void main() {
  testWidgets('signs in', (WidgetTester tester) async {
    await tester.pumpWidget(
        MyApp.withParameters(MockFirebaseAuth(), MockGoogleSignIn()));

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('hello'), findsNothing);

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('displays messages', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ChatView.withParameters(MockChatService()))));
    await tester.pump();

    expect(find.text('hello!'), findsOneWidget);
    expect(find.byType(MessageInput), findsOneWidget);
  });
}

class MockChatService extends Mock implements ChatService {
  Stream<List<String>> getMessages() {
    return Stream.fromIterable([
      ['hello!']
    ]);
  }
}
