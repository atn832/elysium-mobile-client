import 'package:flutter/material.dart';

import 'message.dart';

class MessageWidget extends StatefulWidget {
  final Message message;

  MessageWidget(this.message);

  @override
  State<StatefulWidget> createState() {
    return _MessageWidgetState();
  }
}

class _MessageWidgetState extends State<MessageWidget> {
  @override
  Widget build(BuildContext context) {
    final m = widget.message;
    return Text(m.author.name + ': ' + m.message);
  }
}
