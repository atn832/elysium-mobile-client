import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'bubble_service.dart';
import 'bubble_widget.dart';
import 'chatservice.dart';
import 'message.dart';
import 'message_input.dart';
import 'message_widget.dart';

class ChatView extends StatefulWidget {
  final ChatService _service;

  ChatView() : this.withParameters(ChatService());

  ChatView.withParameters(this._service);

  @override
  State<StatefulWidget> createState() {
    return _ChatViewState();
  }
}

class _ChatViewState extends State<ChatView> {
  ScrollController _controller = ScrollController();

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
}
