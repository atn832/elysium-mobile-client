import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
            child: TextField(
          controller: _controller,
          onSubmitted: sendMessage,
          textInputAction: TextInputAction.send,
          decoration: InputDecoration(
            labelText: 'Envoyer...',
          ),
        )),
        IconButton(
          icon: Icon(Icons.image),
          onPressed: () async {
            final image =
                await ImagePicker().getImage(source: ImageSource.gallery);
            if (image == null) return;
            widget._chatService.sendImage(File(image.path));
          },
        ),
        IconButton(
          icon: Icon(Icons.send),
          onPressed: () {
            final message = _controller.text;
            sendMessage(message);
          },
        )
      ],
    );
  }

  sendMessage(String message) async {
    _controller.clear();
    return widget._chatService.sendMessage(message);
  }
}
