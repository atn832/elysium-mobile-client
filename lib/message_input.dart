import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MessageInput extends StatefulWidget {
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
          _controller.clear();
        },
      ))
    ]);
  }
}
