import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'message.dart';
import 'user.dart';

const LocationKey = 'location';
const TimezoneKey = 'timezone';

class ChatService {
  final Firestore instance;
  final FirebaseAuth authInstance;
  final FirebaseStorage storage;
  final Geolocator geolocator;
  final Future<String> Function() getLocalTimezone;
  final DateTime now;
  Future<DateTime> from;
  Position position;

  ChatService()
      : this.withParameters(
            Firestore.instance,
            FirebaseAuth.instance,
            FirebaseStorage.instance,
            Geolocator(),
            FlutterNativeTimezone.getLocalTimezone,
            DateTime.now());

  ChatService.withParameters(this.instance, this.authInstance, this.storage,
      this.geolocator, this.getLocalTimezone, this.now) {
    from = getUserMap().first.then((users) async {
      final lastTalked = users[await myUid].lastTalked;
      if (lastTalked != null) {
        return lastTalked.subtract(Duration(minutes: 10));
      } else if (now != null) {
        return now.subtract(Duration(days: 1));
      } else {
        return DateTime.now();
      }
    });

    maybeSubscribeToGeolocation();
  }

  maybeSubscribeToGeolocation() async {
    final locationOptions =
        LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
    if (geolocator == null) {
      return;
    }
    geolocator.getPositionStream(locationOptions).listen((Position position) {
      this.position = position;
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
            final point = d.data[LocationKey] as GeoPoint;
            final position = point != null
                ? Position(latitude: point.latitude, longitude: point.longitude)
                : null;
            return Message()
              ..author = users[d.data['uid']]
              ..message = d.data['content'] as String
              ..time = (d.data['timestamp'] as Timestamp).toDate()
              ..position = position;
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
    final Map<String, dynamic> data = {
      'uid': await myUid,
      'content': message,
      'timestamp': timestamp,
    };
    if (position != null) {
      data[LocationKey] = GeoPoint(position.latitude, position.longitude);
    }
    await instance.collection('messages').add(data);
    final Map<String, dynamic> userData = {
      'lastTalked': timestamp,
    };
    if (getLocalTimezone != null) {
      userData[TimezoneKey] = await getLocalTimezone();
    }
    await instance
        .collection('users')
        .document(await myUid)
        .setData(userData, merge: true);
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
