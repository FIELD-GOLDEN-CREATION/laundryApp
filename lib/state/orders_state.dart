import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/order.dart';
import '../models/order_line.dart';

/// Active orders, mutable so Checkout can insert a freshly placed order at
/// the top and Track can advance its step on its own — independent of the
/// other seed orders in mock_data.dart. Completed orders stay static
/// (kCompletedOrders); nothing in this app moves an order into that list.
class OrdersNotifier extends Notifier<List<Order>> {
  int _placedCount = 0;

  @override
  List<Order> build() => kActiveOrders;

  /// Inserts a new order at the top of Active, at kOrderPlacedStep (i.e.
  /// submitted but not yet picked up).
  Order placeOrder({
    required String shop,
    required String items,
    required String total,
    String paymentMethod = '',
    String pickup = '',
    String address = '',
    List<OrderLine> lines = const [],
    String fulfillment = 'delivery',
    String driver = '',
    int deliveryFeeTzs = 0,
  }) {
    _placedCount++;
    final placed = orderStatusForStep(kOrderPlacedStep);
    final order = Order(
      shop: shop,
      id: '#LD-${3000 + _placedCount}',
      items: items,
      status: placed.label,
      statusFg: placed.fg,
      statusBg: placed.bg,
      date: 'Just now',
      total: total,
      trackStep: kOrderPlacedStep,
      paymentMethod: paymentMethod,
      pickup: pickup,
      address: address,
      lines: lines,
      fulfillment: fulfillment,
      driver: driver,
      deliveryFeeTzs: deliveryFeeTzs,
    );
    state = [order, ...state];
    return order;
  }

  /// Demo-only control (ported from the old global TrackingNotifier.advance)
  /// that cycles one order through placed -> picked up -> ... -> delivery
  /// and back, so its progress can be watched without a real driver.
  void advanceStep(String id) {
    state = [
      for (final o in state)
        if (o.id == id) _withNextStep(o) else o,
    ];
  }

  Order _withNextStep(Order o) {
    final next = o.trackStep >= 3 ? kOrderPlacedStep : o.trackStep + 1;
    final status = o.fulfillment == 'self' ? selfOrderStatusForStep(next) : orderStatusForStep(next);
    return o.copyWith(trackStep: next, status: status.label, statusFg: status.fg, statusBg: status.bg);
  }
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);
