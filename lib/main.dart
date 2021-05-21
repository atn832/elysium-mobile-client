// Gotta use unsound null safety because of geocoder.
// @dart=2.9

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart';

import 'app.dart';

const AppLocale = 'fr';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeTimeZones();
  await initializeDateFormatting(AppLocale);
  await Firebase.initializeApp();
  runApp(MyApp());
}
