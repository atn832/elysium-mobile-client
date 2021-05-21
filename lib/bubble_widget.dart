import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'bubble.dart';
import 'main.dart';
import 'message_widget.dart';
import 'position.dart';

class BubbleWidget extends StatefulWidget {
  final Bubble bubble;

  BubbleWidget(this.bubble);

  @override
  State<StatefulWidget> createState() {
    return _BubbleWidgetState();
  }
}

class _BubbleWidgetState extends State<BubbleWidget> {
  DateFormat? timeFormat;
  DateFormat? dateTimeFormat;

  @override
  void initState() {
    initializeDateFormatting(AppLocale).then((_) {
      if (!mounted) return;

      setState(() {
        // 08:27
        timeFormat = DateFormat.Hm(AppLocale);
        // Fri 14 Jun, 08:27
        dateTimeFormat = DateFormat.yMMMMEEEEd(AppLocale).add_Hm();
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bubble;
    final now = DateTime.now();
    final todayAtMidnight =
        now.subtract(Duration(hours: now.hour, minutes: now.minute));
    final bubbleTime = b.messages.last.time;
    final isFromToday = bubbleTime.isAfter(todayAtMidnight);
    final formatter = isFromToday ? timeFormat : dateTimeFormat;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Card(
          shape: CircleBorder(),
          child: Container(
            padding: EdgeInsets.all(12),
            child: Text(
              b.author.name?[0] ?? '?',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          )),
      Expanded(
          child: Card(
              child: Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final m in b.messages) MessageWidget(m),
                        if (b.position != null)
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                PositionWidget(b.position!),
                              ]),
                        if (timeFormat != null)
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(formatter!.format(bubbleTime)),
                              ])
                      ])))),
    ]);
  }
}

final cache = Map<String, List<Address>?>();

extension on Coordinates {
  String get toCacheKey => toString();
}

class PositionWidget extends StatelessWidget {
  final Position position;

  PositionWidget(this.position);

  toKey(Coordinates coordinates) => coordinates.toString();

  @override
  Widget build(BuildContext context) {
    final coordinates = Coordinates(position.latitude, position.longitude);
    if (cache.containsKey(coordinates.toCacheKey)) {
      final addresses = cache[coordinates.toCacheKey];
      return SynchronousPositionWidget(coordinates, addresses);
    }
    return FutureBuilder<List<Address>>(
        future: Geocoder.local.findAddressesFromCoordinates(coordinates),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Expanded(child: LinearProgressIndicator());
          }
          final addresses = snapshot.data;
          cache[coordinates.toCacheKey] = addresses;
          return SynchronousPositionWidget(coordinates, addresses);
        });
  }
}

class SynchronousPositionWidget extends StatelessWidget {
  SynchronousPositionWidget(this.coordinates, this.addresses);

  final Coordinates coordinates;
  final List<Address>? addresses;

  @override
  Widget build(BuildContext context) {
    if (addresses == null || addresses!.isEmpty) {
      return Text(coordinates.latitude.toStringAsFixed(2) +
          ', ' +
          coordinates.longitude.toStringAsFixed(2));
    }
    final address = addresses!.first;
    print(address.toMap());
    final components = [
      address.subLocality,
      address.locality,
      address.subAdminArea,
      address.adminArea,
    ].where((/* geocoder's Strings are nullable */ String? element) =>
        element != null && element.isNotEmpty);
    return Text(components.join(', '));
  }
}
