import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import '../services/api_service.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
  });

  final List<NotificationItem> items;
  final bool isLoading;

  int get unreadCount => items.length;

  NotificationsState copyWith({List<NotificationItem>? items, bool? isLoading}) =>
      NotificationsState(items: items ?? this.items, isLoading: isLoading ?? this.isLoading);
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getNotifications();
      final items = data.map((j) => NotificationItem(
        initial: j['initial'] as String? ?? (j['title'] as String?)?[0] ?? 'N',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? j['message'] as String? ?? '',
        time: j['time'] as String? ?? j['created_at'] as String? ?? '',
        bg: const Color(0xFFFFFFFF),
        iconBg: const Color(0xFFE0F2F1),
        iconFg: const Color(0xFF00897B),
      )).toList();
      state = state.copyWith(items: items, isLoading: false);
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await api.markNotificationRead(id);
    } on ApiException {
      // Best effort
    }
  }

  Future<void> markAllRead() async {
    try {
      await api.markAllNotificationsRead();
    } on ApiException {
      // Best effort
    }
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, NotificationsState>(NotificationsNotifier.new);
