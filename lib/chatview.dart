import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'bubble_service.dart';
import 'bubble_widget.dart';
import 'chatservice.dart';
import 'get_more_button.dart';
import 'message.dart';
import 'message_input.dart';
import 'user.dart';
import 'user_list_widget.dart';

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
  bool stickToBottom = true;

  @override
  void initState() {
    maybeSendSharedData();
    WidgetsBinding.instance?.addObserver(this);
    // Update stickToBottom flag.
    _controller.addListener(() {
      stickToBottom = _controller.position.extentAfter == 0;
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance?.removeObserver(this);
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
      if (results[0] == null || results[1] == null) {
        return;
      }
      final filename = DateTime.now().toIso8601String() + '.png';
      final imageBytes = results[1] as Uint8List;
      widget._service.sendImageData(filename, imageBytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = widget._service;
    return Column(children: [
      StreamBuilder<List<User>>(
          stream: service.getUsers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Expanded(child: LinearProgressIndicator());
            }
            final users = snapshot.data!;
            return UserListWidget(users);
          }),
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
                if (stickToBottom) {
                  WidgetsBinding.instance
                      ?.addPostFrameCallback((Duration timeStamp) {
                    scrollDown();
                  });
                }
                final bubbles = BubbleService.getBubbles(snapshot.data!);
                return Expanded(
                    child: ListView.builder(
                        controller: _controller,
                        itemCount: bubbles.length + 1,
                        itemBuilder: (BuildContext context, int index) {
                          if (index == 0) {
                            return GetMoreButton(service);
                          }
                          return Container(
                              child: BubbleWidget(bubbles[index - 1]),
                              padding: EdgeInsets.symmetric(horizontal: 16));
                        }));
            }
          }),
      Container(
        color: Color.fromARGB(255, 255, 255, 255),
        padding: EdgeInsets.only(left: 16, bottom: 16),
        child: MessageInput(widget._service),
      ),
    ]);
  }

  scrollDown() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  Future<String?> getSharedText() async {
    return await platform.invokeMethod("getSharedText");
  }

  Future<String?> getSharedImageFilename() async {
    return platform.invokeMethod("getSharedImageFilename");
  }

  Future<List<int>?> getSharedImage() async {
    return platform.invokeMethod("getSharedImage");
  }
}
