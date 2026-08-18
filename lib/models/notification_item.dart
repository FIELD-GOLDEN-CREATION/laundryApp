import 'package:flutter/widgets.dart';

class NotificationItem {
  const NotificationItem({
    required this.initial,
    required this.title,
    required this.body,
    required this.time,
    required this.bg,
    required this.iconBg,
    required this.iconFg,
  });

  final String initial;
  final String title;
  final String body;
  final String time;
  final Color bg;
  final Color iconBg;
  final Color iconFg;
}
