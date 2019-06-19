import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'bubble_service.dart';
import 'bubble_widget.dart';
import 'chatservice.dart';
import 'message.dart';
import 'message_input.dart';

const platform = const MethodChannel('app.channel.shared.data');

class ChatView extends StatefulWidget {
  final ChatService _service;

  ChatView() : this.withParameters(ChatService());

  ChatView.withParameters(this._service);

  @override
  State<StatefulWidget> createState() {
    return _ChatViewState();
  }
}

class _ChatViewState extends State<ChatView> with WidgetsBindingObserver {
  ScrollController _controller = ScrollController();

  @override
  void initState() {
    maybeSendSharedData();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      maybeSendSharedData();
    }
  }

  Future<void> maybeSendSharedData() async {
    await getSharedText().then((text) {
      if (text != null) {
        widget._service.sendMessage(text);
      }
    });
    return Future.wait([getSharedImageFilename(), getSharedImage()])
        .then((results) async {
      final filename = DateTime.now().toIso8601String() + '.png';//results[0];
      final imageBytes = results[1];
      if (filename != null && imageBytes != null) {
        widget._service.sendImageData(filename, imageBytes);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      StreamBuilder<List<Message>>(
          stream: widget._service.getMessages(),
          builder:
              (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              default:
                // Scroll down on redraw.
                WidgetsBinding.instance
                    .addPostFrameCallback((Duration timeStamp) {
                  scrollDown();
                });
                final bubbles = BubbleService.getBubbles(snapshot.data);
                return Expanded(
                    child: ListView.builder(
                        controller: _controller,
                        itemCount: bubbles.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                              child: BubbleWidget(bubbles[index]),
                              padding: EdgeInsets.symmetric(horizontal: 16));
                        }));
            }
          }),
      Container(
        color: Color.fromARGB(255, 255, 255, 255),
        padding: EdgeInsets.only(left: 16, bottom: 16),
        child: MessageInput(widget._service),
      )
    ]);
  }

  scrollDown() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  Future<String> getSharedText() async {
    final sharedData = await platform.invokeMethod("getSharedText");
    return sharedData;
  }

  Future<String> getSharedImageFilename() async {
    return platform.invokeMethod("getSharedImageFilename");
  }

  Future<List<int>> getSharedImage() async {
    return platform.invokeMethod("getSharedImage");
  }
}
