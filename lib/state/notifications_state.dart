import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import '../services/api_service.dart';

NotificationItem notificationFromJson(Map<String, dynamic> j) {
  final title = j['title'] as String? ?? '';
  return NotificationItem(
    id: '${j['id'] ?? ''}',
    initial: (j['initial'] as String?) ?? (title.isNotEmpty ? title[0] : 'N'),
    title: title,
    body: j['body'] as String? ?? j['message'] as String? ?? '',
    time: j['time'] as String? ?? j['created_at'] as String? ?? '',
    bg: const Color(0xFFFFFFFF),
    iconBg: const Color(0xFFE0F2F1),
    iconFg: const Color(0xFF00897B),
    type: j['type'] as String? ?? 'system',
    isRead: j['is_read'] == true || j['is_read'] == 1,
    data: (j['data'] as Map?)?.cast<String, dynamic>() ?? const {},
  );
}

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
  });

  final List<NotificationItem> items;
  final bool isLoading;

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationsState copyWith({List<NotificationItem>? items, bool? isLoading}) =>
      NotificationsState(items: items ?? this.items, isLoading: isLoading ?? this.isLoading);
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();

  Future<void> loadNotifications({bool vendor = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = vendor ? await api.getVendorNotifications() : await api.getNotifications();
      final items = data.map(notificationFromJson).toList();
      state = state.copyWith(items: items, isLoading: false);
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Map<String, dynamic>?> detail(String id, {bool vendor = false}) async {
    try {
      final res = vendor ? await api.getVendorNotificationDetail(id) : await api.getNotificationDetail(id);
      final payload = res['data'] as Map<String, dynamic>?;
      if (payload != null) {
        state = state.copyWith(
          items: [
            for (final n in state.items)
              n.id == id ? n.copyWith(isRead: true) : n,
          ],
        );
      }
      return payload;
    } on ApiException {
      return null;
    }
  }

  Future<void> markRead(String id, {bool vendor = false}) async {
    state = state.copyWith(
      items: [
        for (final n in state.items)
          n.id == id ? n.copyWith(isRead: true) : n,
      ],
    );
    try {
      if (vendor) {
        await api.markVendorNotificationRead(id);
      } else {
        await api.markNotificationRead(id);
      }
    } on ApiException {
      // Best effort
    }
  }

  Future<void> markAllRead({bool vendor = false}) async {
    state = state.copyWith(
      items: [for (final n in state.items) n.copyWith(isRead: true)],
    );
    try {
      if (vendor) {
        await api.markAllVendorNotificationsRead();
      } else {
        await api.markAllNotificationsRead();
      }
    } on ApiException {
      // Best effort
    }
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, NotificationsState>(NotificationsNotifier.new);
