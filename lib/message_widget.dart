import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? imageUrl;

  @override
  void initState() {
    if (isFirebaseImage) {
      widget.service.getImageUri(messageContent).then((uri) {
        if (!mounted) return;

        setState(() {
          imageUrl = uri;
        });
      });
    }
    super.initState();
  }

  String get messageContent => widget.message.message;
  bool get isFirebaseImage => messageContent.startsWith('gs://');
  bool get isLink => messageContent.startsWith(RegExp('https?://'));

  @override
  Widget build(BuildContext context) {
    if (isFirebaseImage) {
      if (imageUrl != null)
        return widget.imageFactory.createImage(imageUrl!);
      else
        return Row(
          children: [
            CircularProgressIndicator(),
          ],
        );
    }
    if (isLink) {
      return InkWell(
          child: Text(
            messageContent,
            style: TextStyle(color: Theme.of(context).accentColor),
          ),
          onTap: () => launch(messageContent));
    }
    return Text(messageContent);
  }
}

class ImageFactory {
  Widget createImage(String url) {
    return OctoImage(
      image: NetworkImage(url),
      progressIndicatorBuilder:
          OctoProgressIndicator.circularProgressIndicator(),
    );
  }
}
