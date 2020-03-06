import 'package:elysium/user.dart';
import 'package:flutter/material.dart';

const lastTalkedThreshold = Duration(days: 7);

class UserListWidget extends StatelessWidget {
  final List<User> users;

  UserListWidget(this.users);

  @override
  Widget build(BuildContext context) {
    final activeUsers = users.where((user) =>
        user.lastTalked != null &&
        DateTime.now().difference(user.lastTalked) < lastTalkedThreshold);
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
                    Text(user.name),
                  ],
                ),
              ),
            )
        ]));
  }
}
