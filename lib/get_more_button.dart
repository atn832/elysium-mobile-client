import 'package:flutter/material.dart';

import 'chatservice.dart';

class GetMoreButton extends StatelessWidget {
  final ChatService _service;

  GetMoreButton(this._service);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
        child: Text('Voir les messages précédents'),
        onPressed: _service.getMoreMessages);
  }
}
