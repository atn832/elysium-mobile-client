import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'user.dart';

class ChatService {
  final Firestore instance;
  final FirebaseAuth authInstance;
  final FirebaseStorage storage;
  final DateTime now;
  Future<DateTime> from;

  ChatService()
      : this.withParameters(Firestore.instance, FirebaseAuth.instance,
            FirebaseStorage.instance, DateTime.now());

  ChatService.withParameters(
      this.instance, this.authInstance, this.storage, this.now) {
    from = getUserMap().first.then((users) async {
      final lastTalked = users[await myUid].lastTalked;
      if (lastTalked != null) {
        return lastTalked.subtract(Duration(minutes: 1));
      } else if (now != null) {
        return now.subtract(Duration(days: 1));
      } else {
        return DateTime.now();
      }
    });
  }

  Stream<List<String>> getMessages() {
    return from.asStream().asyncExpand((time) {
      return getUserMap().transform(StreamTransformer.fromHandlers(handleData:
          (Map<String, User> users, EventSink<List<String>> sink) async {
        instance
            .collection('messages')
            .where('timestamp', isGreaterThan: time)
            .snapshots()
            .forEach((QuerySnapshot data) {
          final messages = data.documents.map((d) {
            final userName = users[d.data['uid']].name;
            return userName + ": " + (d.data['content'] as String);
          }).toList();
          sink.add(messages);
        });
      }));
    });
  }

  Stream<List<User>> getUsers() {
    return instance.collection('users').snapshots().transform(
        StreamTransformer.fromHandlers(
            handleData: (QuerySnapshot data, EventSink<List<User>> sink) {
      final users = data.documents.map((d) {
        DateTime lastTalked;
        if (d.data.containsKey('lastTalked')) {
          lastTalked = (d.data['lastTalked'] as Timestamp).toDate();
        }
        return User()
          ..uid = d.documentID
          ..name = d.data['name'] as String
          ..timezone = d.data['timezone'] as String
          ..lastTalked = lastTalked;
      }).toList();
      sink.add(users);
    }));
  }

  Stream<Map<String, User>> getUserMap() {
    return getUsers().asBroadcastStream().transform(
        StreamTransformer.fromHandlers(
            handleData: (List<User> data, EventSink<Map<String, User>> sink) {
      final result = Map<String, User>();
      for (final user in data) {
        result[user.uid] = user;
      }
      sink.add(result);
    }));
  }

  Future<void> sendMessage(String message, [DateTime now]) async {
    final timestamp = now ?? DateTime.now();
    await instance.collection('messages').add({
      'uid': await myUid,
      'content': message,
      'timestamp': timestamp,
    });
    await instance.collection('users').document(await myUid).setData({
      'lastTalked': timestamp,
    }, merge: true);
  }

  Future<void> sendImage(File image) async {
    final filename = image.path
        .substring(image.path.lastIndexOf('/') + 1)
        .replaceAll(' ', '_');
    print(filename);
    final StorageReference storageRef = storage.ref().child(filename);
    // TODO: show progress and success.
    final task = storageRef.putFile(image);
    await task.onComplete;
    return sendMessage(
        'gs://' + await storageRef.getBucket() + '/' + storageRef.path);
  }

  Future<String> get myUid async => (await authInstance.currentUser()).uid;
}
