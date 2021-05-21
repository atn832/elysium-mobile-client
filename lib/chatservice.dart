import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:geolocator/geolocator.dart' as Geolocator;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:stream_transform/stream_transform.dart';

import 'message.dart';
import 'position.dart';
import 'user.dart';

const LocationKey = 'location';
const TimezoneKey = 'timezone';

class ChatService {
  final FirebaseFirestore instance;
  final FirebaseAuth authInstance;
  final FirebaseStorage storage;
  final Geolocator.Geolocator? geolocator;
  final Future<String> Function()? getLocalTimezone;
  final DateTime? now;
  final StreamController<DateTime> oldestMessageDateController;
  Position? position;
  DateTime? latestThreshold;
  Duration getMoreDuration = Duration(hours: 12);

  ChatService()
      : this.withParameters(
            FirebaseFirestore.instance,
            // FakeFirebaseFirestore(), // Offline testing
            FirebaseAuth.instance,
            FirebaseStorage.instance,
            Geolocator.Geolocator(),
            FlutterNativeTimezone.getLocalTimezone,
            DateTime.now());

  ChatService.withParameters(this.instance, this.authInstance, this.storage,
      this.geolocator, this.getLocalTimezone, this.now)
      : oldestMessageDateController = StreamController<DateTime>.broadcast() {
    oldestMessageDateController.stream.forEach((newThreshold) {
      latestThreshold = newThreshold;
    });
    getUserMap().first.then((users) async {
      final lastTalked = users[myUid]?.lastTalked;
      if (lastTalked != null) {
        return lastTalked.subtract(Duration(minutes: 10));
      } else if (now != null) {
        return now!.subtract(Duration(days: 1));
      } else {
        return DateTime.now();
      }
    }).then((from) {
      oldestMessageDateController.add(from);
    });

    maybeSubscribeToGeolocation();
  }

  maybeSubscribeToGeolocation() async {
    Geolocator.Geolocator.getPositionStream(
            desiredAccuracy: Geolocator.LocationAccuracy.high,
            distanceFilter: 10)
        .listen((Geolocator.Position position) {
      this.position =
          Position(latitude: position.latitude, longitude: position.longitude);
    });
  }

  // Signals the Service to fetch more messages. The stream returned by getMessages
  // will emit a new list of messages.
  void getMoreMessages() async {
    final newThreshold =
        // avoid the race condition where latest threshold hasn't been set
        (latestThreshold ?? await oldestMessageDateController.stream.first)
            .subtract(getMoreDuration);
    oldestMessageDateController.add(newThreshold);
    // Double the duration for the next call.
    getMoreDuration = Duration(seconds: 2 * getMoreDuration.inSeconds);
    latestThreshold = newThreshold;
  }

  Stream<List<Message>> getMessages() {
    return oldestMessageDateController.stream.combineLatest(getUserMap(),
        (time, Map<String, User> users) {
      return instance
          .collection('messages')
          .where('timestamp', isGreaterThan: time)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> data) {
        final messages = data.docs.map((d) {
          final point = d.data()[LocationKey] as GeoPoint?;
          final position = point != null
              ? Position(
                  latitude: point.latitude,
                  longitude: point.longitude,
                )
              : null;
          final uid = d.data()['uid'] as String?;
          return Message()
            ..author = users[uid] ?? (User()..name = uid ?? '?')
            ..message = d.data()['content'] as String
            ..time = (d.data()['timestamp'] as Timestamp).toDate()
            ..position = position;
        }).toList();
        return messages;
      });
    }).switchLatest();
  }

  Stream<List<User>> getUsers() {
    return instance.collection('users').snapshots().transform(
        StreamTransformer.fromHandlers(handleData:
            (QuerySnapshot<Map<String, dynamic>> data,
                EventSink<List<User>> sink) {
      final users = data.docs.map((d) {
        DateTime? lastTalked;
        if (d.data().containsKey('lastTalked')) {
          lastTalked = (d.data()['lastTalked'] as Timestamp).toDate();
        }
        return User()
          ..uid = d.id
          ..name = d.data()['name'] as String?
          ..timezone = d.data()['timezone'] as String
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

  Future<void> sendMessage(String message, [DateTime? now]) async {
    if (message.trim().isEmpty) {
      return;
    }
    final timestamp = now ?? DateTime.now();
    final Map<String, dynamic> data = {
      'uid': myUid,
      'content': message,
      'timestamp': timestamp,
    };
    if (position != null) {
      data[LocationKey] = GeoPoint(position!.latitude, position!.longitude);
    }
    await instance.collection('messages').add(data);
    final Map<String, dynamic> userData = {
      'lastTalked': timestamp,
    };
    if (getLocalTimezone != null) {
      userData[TimezoneKey] = await getLocalTimezone!();
    }
    await instance
        .collection('users')
        .doc(myUid)
        .set(userData, SetOptions(merge: true));
  }

  Future<void> sendImage(File image) async {
    final filename =
        removeSpaces(image.path.substring(image.path.lastIndexOf('/') + 1));
    final Reference storageRef = storage.ref().child(filename);
    final task = storageRef.putFile(image);
    return finalizeSendImageTask(storageRef, task);
  }

  Future<void> sendImageData(String imageFilename, Uint8List data) async {
    final filename = removeSpaces(imageFilename);
    final Reference storageRef = storage.ref().child(filename);
    final task = storageRef.putData(data);
    return finalizeSendImageTask(storageRef, task);
  }

  Future<void> finalizeSendImageTask(Reference storageRef, Task task) async {
    // TODO: show progress and success.
    await task;
    return sendMessage('gs://' + storageRef.bucket + '/' + storageRef.fullPath);
  }

  String removeSpaces(String filename) {
    return filename.replaceAll(' ', '_');
  }

  Future<String> getImageUri(String url) async {
    final ref = storage.refFromURL(url);
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }

  String? get myUid => authInstance.currentUser?.uid;
}
