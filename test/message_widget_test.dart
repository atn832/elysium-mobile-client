import 'dart:async';
import 'dart:typed_data';

import 'package:elysium/chatservice.dart';
import 'package:elysium/message.dart';
import 'package:elysium/message_widget.dart';
import 'package:elysium/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/mockito.dart';

void main() {
  testWidgets('displays messages', (WidgetTester tester) async {
    final m = Message()
      ..author = (User()..name = 'Bob')
      ..message = 'hello!';
    await tester
        .pumpWidget(MaterialApp(home: Scaffold(body: MessageWidget(m))));
    await tester.pump();
    expect(find.text('Bob: hello!'), findsOneWidget);
  });

  testWidgets('displays images', (WidgetTester tester) async {
    const imageStorageUrl = 'gs://some-bucket//IMG_20190609_144619.jpg';
    const downloadUrl = 'https://firebasestorage.googleapis.com/...&token=abcd';
    final m = Message()
      ..author = (User()..name = 'Bob')
      ..message = imageStorageUrl;
    final mockChatService = MockChatService();
    when(mockChatService.getImageUri(imageStorageUrl))
        .thenAnswer((_) => Future.value(downloadUrl));
    final mockImageFactory = MockImageFactory();
    when(mockImageFactory.createImage(downloadUrl)).thenReturn(Image.memory(
        Uint8List.fromList(
            'data:image/gif;base64,R0lGODlhAQABAAAAACwAAAAAAQABAAA='
                .codeUnits)));

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: MessageWidget.withParameters(
                mockChatService, mockImageFactory, m))));
    await tester.pump();

    verify(mockChatService.getImageUri(imageStorageUrl));
    expect(find.byType(Image), findsOneWidget);
  });
}

class MockImageFactory extends Mock implements ImageFactory {}

class MockChatService extends Mock implements ChatService {}
