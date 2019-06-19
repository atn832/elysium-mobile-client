import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'message.dart';
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
        return lastTalked.subtract(Duration(minutes: 5));
      } else if (now != null) {
        return now.subtract(Duration(days: 1));
      } else {
        return DateTime.now();
      }
    });
  }

  Stream<List<Message>> getMessages() {
    return from.asStream().asyncExpand((time) {
      return getUserMap().transform(StreamTransformer.fromHandlers(handleData:
          (Map<String, User> users, EventSink<List<Message>> sink) async {
        instance
            .collection('messages')
            .where('timestamp', isGreaterThan: time)
            .snapshots()
            .forEach((QuerySnapshot data) {
          final messages = data.documents.map((d) {
            return Message()
              ..author = users[d.data['uid']]
              ..message = d.data['content'] as String
              ..time = (d.data['timestamp'] as Timestamp).toDate();
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
    final filename =
        removeSpaces(image.path.substring(image.path.lastIndexOf('/') + 1));
    final StorageReference storageRef = storage.ref().child(filename);
    final task = storageRef.putFile(image);
    return finalizeSendImageTask(storageRef, task);
  }

  Future<void> sendImageData(String imageFilename, List<int> data) async {
    final filename = removeSpaces(imageFilename);
    final StorageReference storageRef = storage.ref().child(filename);
    final task = storageRef.putData(data);
    return finalizeSendImageTask(storageRef, task);
  }

  Future<void> finalizeSendImageTask(
      StorageReference storageRef, StorageUploadTask task) async {
    // TODO: show progress and success.
    await task.onComplete;
    return sendMessage(
        'gs://' + await storageRef.getBucket() + '/' + storageRef.path);
  }

  String removeSpaces(String filename) {
    return filename.replaceAll(' ', '_');
  }

  Future<String> getImageUri(String url) async {
    final ref = await storage.getReferenceFromUrl(url);
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl as String;
  }

  Future<String> get myUid async => (await authInstance.currentUser()).uid;
}
