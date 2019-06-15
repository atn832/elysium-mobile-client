import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

import 'chatservice.dart';
import 'message.dart';

class MessageWidget extends StatefulWidget {
  final ChatService service;
  final Message message;
  final ImageFactory imageFactory;

  MessageWidget(message)
      : this.withParameters(ChatService(), ImageFactory(), message);

  MessageWidget.withParameters(this.service, this.imageFactory, this.message);

  @override
  State<StatefulWidget> createState() {
    return _MessageWidgetState();
  }
}

class _MessageWidgetState extends State<MessageWidget> {
  String imageUrl;

  @override
  void initState() {
    if (isFirebaseImage) {
      widget.service.getImageUri(messageContent).then((uri) {
        setState(() {
          imageUrl = uri;
        });
      });
    }
    super.initState();
  }

  String get messageContent => widget.message.message;
  bool get isFirebaseImage => messageContent.startsWith('gs://');

  @override
  Widget build(BuildContext context) {
    if (isFirebaseImage) {
      if (imageUrl != null)
        return widget.imageFactory.createImage(imageUrl);
      else
        return Row(
          children: [
            CircularProgressIndicator(),
          ],
        );
    }
    final m = widget.message;
    return Text(m.author.name + ': ' + messageContent);
  }
}

class ImageFactory {
  Widget createImage(String url) {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
        FadeInImage.memoryNetwork(
          placeholder: kTransparentImage,
          image: url,
        ),
      ],
    );
  }
}