import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'chatservice.dart';

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
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
          child: StreamBuilder<List<String>>(
              initialData: ['test'],
              stream: widget._service.getMessages(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return CircularProgressIndicator();
                  default:
                    return ListView.builder(
                        itemCount: snapshot.data.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Text(snapshot.data[index]);
                        });
                }
              }))
    ]);
  }
}
