import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ports the source's `orderTab` field (0 = Active, 1 = Completed).
class OrdersTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void pick(int i) => state = i;
}

final ordersTabProvider = NotifierProvider<OrdersTabNotifier, int>(OrdersTabNotifier.new);
