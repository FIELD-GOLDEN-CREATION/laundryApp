import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import '../services/api_service.dart';

NotificationItem notificationFromJson(Map<String, dynamic> j) {
  final title = j['title'] as String? ?? '';
  final data = (j['data'] as Map?)?.cast<String, dynamic>() ?? const {};
  final rawRead = j['is_read'];
  final readAt = j['read_at'];
  final isRead = rawRead == true ||
      rawRead == 1 ||
      (readAt is String && readAt.isNotEmpty);
  return NotificationItem(
    id: '${j['id'] ?? ''}',
    initial: (j['initial'] as String?) ?? (title.isNotEmpty ? title[0] : 'N'),
    title: title,
    body: j['body'] as String? ?? j['message'] as String? ?? j['description'] as String? ?? '',
    time: j['time'] as String? ?? j['created_at'] as String? ?? '',
    bg: const Color(0xFFFFFFFF),
    iconBg: const Color(0xFFE0F2F1),
    iconFg: const Color(0xFF00897B),
    type: j['type'] as String? ?? 'system',
    event: j['event'] as String?,
    isRead: isRead,
    data: data,
  );
}

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.unreadCount = 0,
    this.activeType = 'all',
  });

  final List<NotificationItem> items;
  final bool isLoading;
  final int unreadCount;
  final String activeType;

  List<NotificationItem> get filtered => activeType == 'all'
      ? items
      : items.where((n) => n.type == activeType).toList();

  NotificationsState copyWith({List<NotificationItem>? items, bool? isLoading, int? unreadCount, String? activeType}) =>
      NotificationsState(
          items: items ?? this.items,
          isLoading: isLoading ?? this.isLoading,
          unreadCount: unreadCount ?? this.unreadCount,
          activeType: activeType ?? this.activeType);
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();

  /// Called by [RealtimeService] for every `notification.created` socket
  /// event on this user's private channel — patches state directly for an
  /// instant bump since the payload already carries everything the list
  /// needs, same as `VendorDashboardNotifier.handleRealtimeNotification`.
  void handleRealtimeNotification(Map<String, dynamic> json) {
    final notif = notificationFromJson(json);
    if (state.items.any((n) => n.id == notif.id)) return;
    state = state.copyWith(
      items: [notif, ...state.items],
      unreadCount: notif.isRead ? state.unreadCount : state.unreadCount + 1,
    );
  }

  Future<void> loadNotifications({bool vendor = false, String? type}) async {
    state = state.copyWith(isLoading: true);
    try {
      final t = type == 'all' ? null : type;
      final data = vendor
          ? await api.getVendorNotifications(type: t)
          : await api.getNotifications(type: t);
      final items = data.map(notificationFromJson).toList();
      final unread = vendor
          ? await api.getVendorNotificationsUnreadCount()
          : await api.getNotificationsUnreadCount();
      state = state.copyWith(
        items: items,
        isLoading: false,
        unreadCount: unread > 0 ? unread : items.where((n) => !n.isRead).length,
      );
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshUnread({bool vendor = false}) async {
    final unread = vendor
        ? await api.getVendorNotificationsUnreadCount()
        : await api.getNotificationsUnreadCount();
    state = state.copyWith(unreadCount: unread);
  }

  void setFilter(String type) {
    state = state.copyWith(activeType: type);
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
    final wasUnread = state.items.any((n) => n.id == id && !n.isRead);
    state = state.copyWith(
      items: [
        for (final n in state.items)
          n.id == id ? n.copyWith(isRead: true) : n,
      ],
      unreadCount: wasUnread ? state.unreadCount - 1 : state.unreadCount,
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
    final prev = state.items;
    state = state.copyWith(
      items: [for (final n in state.items) n.copyWith(isRead: true)],
      unreadCount: 0,
    );
    try {
      if (vendor) {
        await api.markAllVendorNotificationsRead();
      } else {
        await api.markAllNotificationsRead();
      }
    } on ApiException {
      state = state.copyWith(
        items: prev,
        unreadCount: prev.where((n) => !n.isRead).length,
      );
    }
  }

  Future<void> deleteNotification(String id, {bool vendor = false}) async {
    final prev = state.items;
    state = state.copyWith(
      items: [for (final n in state.items) if (n.id != id) n],
      unreadCount: [for (final n in state.items) if (n.id != id && !n.isRead) n].length,
    );
    try {
      if (vendor) {
        await api.deleteVendorNotification(id);
      } else {
        await api.deleteNotification(id);
      }
    } on ApiException {
      state = state.copyWith(items: prev);
    }
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, NotificationsState>(NotificationsNotifier.new);
