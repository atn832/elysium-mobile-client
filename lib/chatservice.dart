import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user.dart';

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

  Stream<List<User>> getUsers() {
    return instance.collection('users').snapshots().transform(
        StreamTransformer.fromHandlers(
            handleData: (QuerySnapshot data, EventSink<List<User>> sink) {
      final users = data.documents
          .map((d) => User()
            ..uid = d.documentID
            ..name = d.data['name'] as String
            ..timezone = d.data['timezone'] as String)
          .toList();
      sink.add(users);
    }));
  }

  Stream<Map<String, User>> getUserMap() {
    return getUsers().transform(StreamTransformer.fromHandlers(
      handleData: (List<User> data, EventSink<Map<String, User>> sink) {
        final result = Map<String, User>();
        for (final user in data) {
          result[user.uid] = user;
        }
        sink.add(result);
      }
    ));
  }
}
