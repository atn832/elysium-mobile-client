// This is a basic Flutter widget test.
// To perform an interaction with a widget in your test, use the WidgetTester utility that Flutter
// provides. For example, you can send tap and scroll gestures. You can also use WidgetTester to
// find child widgets in the widget tree, read text, and verify that the values of widget properties
// are correct.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elysium/main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

void main() {
  testWidgets('signs in', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp.withParameters(MockFirebaseAuth(), MockGoogleSignIn()));

    // Verify that our counter starts at 0.
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('hello'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Sign in'), findsNothing);
  });
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  final stateChangedStreamController = StreamController<FirebaseUser>();

  @override
  Future<FirebaseUser> signInWithCredential(AuthCredential credential) {
    print('Fake sign in.');
    final user = MockFirebaseUser();
    stateChangedStreamController.add(user);
    return Future.value(user);
  }

  @override
  Stream<FirebaseUser> get onAuthStateChanged => stateChangedStreamController.stream;
}

class MockGoogleSignIn extends Mock implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount> signIn() {
    return Future.value(MockGoogleSignInAccount());
  }
}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {
  @override
  Future<GoogleSignInAuthentication> get authentication => Future.value(MockGoogleSignInAuthentication());
}

class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}

class MockFirebaseUser extends Mock implements FirebaseUser {
  @override
  String get displayName => 'Bob';
}