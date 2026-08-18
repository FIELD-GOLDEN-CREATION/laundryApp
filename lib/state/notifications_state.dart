import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/notification_item.dart';

/// The customer's notification feed, seeded from the static demo list but
/// mutable so events like a vendor accepting/rejecting an order can push a
/// fresh notification onto it — see `widgets/vendor_accept_order_sheet.dart`
/// and `widgets/vendor_reject_order_sheet.dart`.
class NotificationsNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() => kNotifications;

  void addNotification(NotificationItem item) => state = [item, ...state];
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<NotificationItem>>(NotificationsNotifier.new);
