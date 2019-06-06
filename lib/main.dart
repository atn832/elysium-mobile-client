import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'chatview.dart';

void main() => runApp(new MyApp());

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
  MyHomePage({Key key, this.title, this.auth, this.googleSignIn})
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

    widget.auth.onAuthStateChanged.listen((user) {
      print(user);
      setState(() {
        signedIn = user != null;
        print(signedIn);
      });
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
                    })
              ],
            ))
          : ChatView(),
    );
  }
}

Future<FirebaseUser> _handleSignIn(
    FirebaseAuth auth, GoogleSignIn googleSignIn) async {
  final GoogleSignInAccount googleUser = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  final FirebaseUser user = await auth.signInWithCredential(credential);
  return user;
}
