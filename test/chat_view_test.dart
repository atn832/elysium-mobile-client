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
const fakeImageFilename = "image.png";
const fakeImageData = <dynamic>[10, 200, 100];

void main() {
  testWidgets('sends shared text', (WidgetTester tester) async {
    platform.setMockMethodCallHandler((methodCall) {
      if (methodCall.method == "getSharedText")
        return Future.value('http://www.google.com');
      else {
        return Future.value(null);
      }
    });

    final chatService = MockChatService();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ChatView.withParameters(chatService))));

    await tester.pump();

    verify(chatService.sendMessage('http://www.google.com'));
  });

  // TODO: fix error `type 'List<dynamic>' is not a subtype of type 'List<int>'`.
//  testWidgets('sends shared image', (WidgetTester tester) async {
//    platform.setMockMethodCallHandler((methodCall) {
//      switch(methodCall.method) {
//        case "getSharedImageFilename":
//          return Future.value(fakeImageFilename);
//        case "getSharedImage":
//          return Future.value(fakeImageData);
//        default:
//          return Future.value(null);
//      }
//    });
//
//    final chatService = MockChatService();
//    await tester.pumpWidget(MaterialApp(
//        home: Scaffold(body: ChatView.withParameters(chatService))));
//
//    await tester.pump();
//
//    verify(chatService.sendImageData(fakeImageFilename, fakeImageData));
//  });
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
