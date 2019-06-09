import 'dart:async';

import 'package:elysium/chatservice.dart';
import 'package:elysium/chatview.dart';
import 'package:elysium/message.dart';
import 'package:elysium/message_input.dart';
import 'package:elysium/message_widget.dart';
import 'package:elysium/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elysium/main.dart';
import 'package:mockito/mockito.dart';

import 'firebase_auth_mocks.dart';

void main() {
  testWidgets('displays messages', (WidgetTester tester) async {
    final m = Message()
      ..author = (User()..name = 'Bob')
      ..message = 'hello!';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: MessageWidget(m))));
    await tester.pump();

    expect(find.text('Bob: hello!'), findsOneWidget);
  });
}
