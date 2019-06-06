import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  final stateChangedStreamController = StreamController<FirebaseUser>();
  FirebaseUser _currentUser;

  MockFirebaseAuth({signedIn = false}) {
    if (signedIn) {
      signInWithCredential(null);
    }
  }

  Future<FirebaseUser> currentUser() {
    return Future.value(_currentUser);
  }

  @override
  Future<FirebaseUser> signInWithCredential(AuthCredential credential) {
    _currentUser = MockFirebaseUser();
    stateChangedStreamController.add(_currentUser);
    return Future.value(_currentUser);
  }

  @override
  Stream<FirebaseUser> get onAuthStateChanged =>
      stateChangedStreamController.stream;
}

class MockGoogleSignIn extends Mock implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount> signIn() {
    return Future.value(MockGoogleSignInAccount());
  }
}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {
  @override
  Future<GoogleSignInAuthentication> get authentication =>
      Future.value(MockGoogleSignInAuthentication());
}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockFirebaseUser extends Mock implements FirebaseUser {
  @override
  String get displayName => 'Bob';

  @override
  String get uid => 'aabbcc';
}
