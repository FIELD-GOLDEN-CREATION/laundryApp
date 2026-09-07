import 'package:flutter/widgets.dart';

class NotificationItem {
  const NotificationItem({
    this.id = '',
    required this.initial,
    required this.title,
    required this.body,
    required this.time,
    required this.bg,
    required this.iconBg,
    required this.iconFg,
    this.type = 'system',
    this.event,
    this.isRead = false,
    this.data = const {},
  });

  final String id;
  final String initial;
  final String title;
  final String body;
  final String time;
  final Color bg;
  final Color iconBg;
  final Color iconFg;

  /// Backend `notifications.type`: order | vendor | payment | system.
  final String type;

  /// Canonical backend `notifications.event` (order.placed, promo.created, ...).
  final String? event;

  /// Whether the notification has been read.
  final bool isRead;

  /// Raw backend `data` payload (order ids, ratings, ...).
  final Map<String, dynamic> data;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        initial: initial,
        title: title,
        body: body,
        time: time,
        bg: bg,
        iconBg: iconBg,
        iconFg: iconFg,
        type: type,
        event: event,
        isRead: isRead ?? this.isRead,
        data: data,
      );
}
