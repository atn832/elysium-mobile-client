import 'package:geolocator/geolocator.dart';

import 'message.dart';
import 'user.dart';

class Bubble {
  User author;
  List<Message> messages;
  Position position;
}
