import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'bubble.dart';
import 'message_widget.dart';

class BubbleWidget extends StatefulWidget {
  final Bubble bubble;

  BubbleWidget(this.bubble);

  @override
  State<StatefulWidget> createState() {
    return _BubbleWidgetState();
  }
}

class _BubbleWidgetState extends State<BubbleWidget> {
  @override
  Widget build(BuildContext context) {
    final b = widget.bubble;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Card(
          shape: CircleBorder(),
          child: Container(
            padding: EdgeInsets.all(8),
            child: Text(
              b.author.name[0],
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          )),
      Expanded(
          child: Card(
              child: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final m in b.messages) MessageWidget(m)
                      ])))),
    ]);
  }
}
