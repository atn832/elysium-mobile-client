import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'chatservice.dart';

class MessageInput extends StatefulWidget {
  final ChatService _chatService;
  MessageInput(this._chatService);

  @override
  State<StatefulWidget> createState() {
    return _MessageInputState();
  }
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: TextField(
        controller: _controller,
        onSubmitted: (String value) {
          print('On Submit');
        },
      )),
      IconButton(
        icon: Icon(Icons.send),
        onPressed: () {
          final message = _controller.text;
          _controller.clear();
          widget._chatService.sendMessage(message);
        },
      )
    ]);
  }
}
