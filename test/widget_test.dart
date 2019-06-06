// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester utility that Flutter
// provides. For example, you can send tap and scroll gestures. You can also use WidgetTester to
// find child widgets in the widget tree, read text, and verify that the values of widget properties
// are correct.

import 'dart:async';

import 'package:elysium/chatservice.dart';
import 'package:elysium/chatview.dart';
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
    await tester.pumpWidget(
        MaterialApp(home: ChatView.withParameters(MockChatService())));
    await tester.pump();

    expect(find.text('hello!'), findsOneWidget);
  });
}

class MockChatService extends Mock implements ChatService {
  Stream<List<String>> getMessages() {
    return Stream.fromIterable([
      ['hello!']
    ]);
  }
}
