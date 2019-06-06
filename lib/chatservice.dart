import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final Firestore instance;
  final FirebaseAuth authInstance;
  final DateTime now;
  DateTime from;

  ChatService()
      : this.withParameters(
            Firestore.instance, FirebaseAuth.instance, DateTime.now());

  ChatService.withParameters(this.instance, this.authInstance, this.now) {
    from = now.subtract(Duration(days: 1));
  }

  Stream<List<String>> getMessages() {
    return instance
        .collection('messages')
        .where('timestamp', isGreaterThan: from)
        .snapshots()
        .transform(StreamTransformer.fromHandlers(
            handleData: (QuerySnapshot data, EventSink<List<String>> sink) {
      final messages =
          data.documents.map((d) => d.data['content'] as String).toList();
      sink.add(messages);
    }));
  }
}
