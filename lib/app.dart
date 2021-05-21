import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'chatview.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

class MyApp extends StatelessWidget {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  MyApp() : this.withParameters(FirebaseAuth.instance, GoogleSignIn());

  MyApp.withParameters(final this._auth, final this._googleSignIn);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elysium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: 'Elysium',
        auth: _auth,
        googleSignIn: _googleSignIn,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(
      {Key? key,
      required this.title,
      required this.auth,
      required this.googleSignIn})
      : super(key: key);

  final String title;
  final FirebaseAuth auth;
  final GoogleSignIn googleSignIn;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var signedIn = false;

  @override
  void initState() {
    super.initState();

    widget.auth.authStateChanges().listen((user) {
      setState(() {
        signedIn = user != null;
      });
      if (user != null) {
        _firebaseMessaging.subscribeToTopic(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: !signedIn
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RaisedButton(
                    child: Text('Sign in'),
                    onPressed: () {
                      _handleSignIn(widget.auth, widget.googleSignIn);
                      _firebaseMessaging.requestPermission();
                    })
              ],
            ))
          : ChatView(),
    );
  }
}

Future<AuthCredential?> _signInWithGoogle(
    FirebaseAuth auth, GoogleSignIn googleSignIn) async {
  final googleUser = await googleSignIn.signIn();
  if (googleUser == null) {
    return null;
  }
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  return credential;
}

Future<void> _handleSignIn(FirebaseAuth auth, GoogleSignIn googleSignIn) async {
  final credential = await _signInWithGoogle(auth, googleSignIn);
  if (credential == null) {
    return;
  }
  await auth.signInWithCredential(credential);
}
