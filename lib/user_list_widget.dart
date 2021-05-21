import 'package:elysium/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

import 'main.dart';

const lastTalkedThreshold = Duration(days: 7);
// 08:27
final timeFormat = DateFormat.Hm(AppLocale);

class UserListWidget extends StatelessWidget {
  final List<User>? users;

  UserListWidget(this.users);

  @override
  Widget build(BuildContext context) {
    final activeUsers = users?.where((user) =>
            user.lastTalked != null &&
            DateTime.now().difference(user.lastTalked!) <
                lastTalkedThreshold) ??
        [];
    return Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Row(children: [
          for (final user in activeUsers)
            Card(
              margin: EdgeInsets.only(right: 16),
              child: Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Text(user.name ?? '?'),
                    if (user.timezone != null) ...[
                      SizedBox(width: 16),
                      if (user.timezone != null) LocalTimeWidget(user.timezone!)
                    ]
                  ],
                ),
              ),
            )
        ]));
  }
}

class LocalTimeWidget extends StatelessWidget {
  final String timezoneName;

  LocalTimeWidget(this.timezoneName);

  @override
  Widget build(BuildContext context) {
    final location = getLocation(timezoneName);
    final remoteTime = TZDateTime.from(DateTime.now(), location);
    return Text(timeFormat.format(remoteTime));
  }
}
