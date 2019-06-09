import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'chatservice.dart';
import 'message.dart';
import 'message_input.dart';

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
                return CircularProgressIndicator();
              default:
                // Scroll down on redraw.
                WidgetsBinding.instance
                    .addPostFrameCallback((Duration timeStamp) {
                  scrollDown();
                });
                return Expanded(
                    child: ListView.builder(
                        controller: _controller,
                        itemCount:
                            snapshot.data != null ? snapshot.data.length : 0,
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                              child: Text(snapshot.data[index].author.name +
                                  ': ' +
                                  snapshot.data[index].message),
                              padding: EdgeInsets.symmetric(horizontal: 16));
                        }));
            }
          }),
      Divider(),
      Container(
        margin: EdgeInsets.all(16),
        child: MessageInput(widget._service),
      )
    ]);
  }

  scrollDown() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }
}
