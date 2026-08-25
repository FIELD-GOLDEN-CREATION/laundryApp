import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../models/order_line.dart';
import '../services/api_service.dart';

/// Active orders, fetched from the API and mutable so Checkout can insert a
/// freshly placed order at the top and Track can advance its step.
class OrdersNotifier extends Notifier<List<Order>> {
  bool _loading = false;
  bool get isLoading => _loading;

  @override
  List<Order> build() => [];

  Future<void> loadOrders() async {
    _loading = true;
    try {
      final data = await api.getOrders();
      state = data.map((j) => orderFromJson(j)).toList();
    } on ApiException {
      // Keep existing state on network errors
    } finally {
      _loading = false;
    }
  }

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
    String customerName = '',
    String customerPhone = '',
    String? shopId,
  }) {
    final placed = orderStatusForStep(kOrderPlacedStep);
    final order = Order(
      shop: shop,
      id: '#LD-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
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
      customerName: customerName,
      customerPhone: customerPhone,
    );
    state = [order, ...state];
    return order;
  }

  /// Calls the API to create an order, then prepends it to local state.
  Future<Order?> createOrderApi({
    required String shopId,
    required List<Map<String, dynamic>> items,
    String fulfillment = 'delivery',
    String? addressId,
    String? scheduledDate,
    String? scheduledTimeSlot,
    String? promoCode,
    String? paymentMethod,
    String? paymentToken,
  }) async {
    try {
      final data = await api.createOrder({
        'shop_id': shopId,
        'items': items,
        'fulfillment': fulfillment,
        if (addressId != null) 'address_id': addressId,
        if (scheduledDate != null) 'scheduled_date': scheduledDate,
        if (scheduledTimeSlot != null) 'scheduled_time_slot': scheduledTimeSlot,
        if (promoCode != null) 'promo_code': promoCode,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (paymentToken != null) 'payment_token': paymentToken,
      });
      final orderData = data['data'] as Map<String, dynamic>? ?? data;
      final order = orderFromJson(orderData);
      state = [order, ...state];
      return order;
    } on ApiException {
      return null;
    }
  }

  void updateDeliveryFee(String id, int deliveryFeeTzs) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(deliveryFeeTzs: deliveryFeeTzs) else o,
    ];
  }

  void advanceStep(String id) {
    state = [
      for (final o in state)
        if (o.id == id) _withNextStep(o) else o,
    ];
  }

  Order _withNextStep(Order o) {
    final next = o.trackStep >= 3 ? kOrderPlacedStep : o.trackStep + 1;
    final status = o.fulfillment == 'self'
        ? selfOrderStatusForStep(next)
        : orderStatusForStep(next);
    return o.copyWith(
      trackStep: next,
      status: status.label,
      statusFg: status.fg,
      statusBg: status.bg,
    );
  }
}

Order orderFromJson(Map<String, dynamic> j) {
  final statusStr = j['status'] as String? ?? 'placed';
  final step = stepFromStatus(statusStr, j['fulfillment'] as String? ?? 'delivery');
  final colors = orderStatusForStep(step);
  final lines = (j['items'] as List?)?.map((l) => OrderLine(
    name: l['name'] as String? ?? '',
    qty: l['quantity'] as int? ?? 1,
    unitPrice: (l['price'] as num?)?.toDouble() ?? 0,
  )).toList() ?? [];

  return Order(
    shop: j['shop_name'] as String? ?? j['shop'] as String? ?? '',
    id: j['id'] != null ? '#LD-${j['id']}' : (j['order_number'] as String? ?? ''),
    items: j['items_summary'] as String? ?? '${lines.length} items',
    status: labelFromStatus(statusStr),
    statusFg: colors.fg,
    statusBg: colors.bg,
    date: j['created_at'] as String? ?? '',
    total: j['total'] != null ? 'TZS ${j['total']}' : (j['total_tzs']?.toString() ?? ''),
    trackStep: step,
    paymentMethod: j['payment_method'] as String? ?? '',
    pickup: j['pickup_time'] as String? ?? '',
    address: j['delivery_address'] as String? ?? '',
    lines: lines,
    fulfillment: j['fulfillment'] as String? ?? 'delivery',
    driver: j['driver_name'] as String? ?? '',
    deliveryFeeTzs: (j['delivery_fee'] as num?)?.toInt() ?? 0,
    customerName: j['customer_name'] as String? ?? '',
    customerPhone: j['customer_phone'] as String? ?? '',
  );
}

int stepFromStatus(String status, String fulfillment) {
  return switch (status) {
    'placed' || 'pending' => kOrderPlacedStep,
    'picked_up' || 'at_shop' => 0,
    'sorted' || 'in_progress' => 1,
    'washing' || 'processing' => 2,
    'out_for_delivery' || 'ready' || 'ready_for_pickup' => 3,
    'delivered' || 'completed' => 3,
    _ => kOrderPlacedStep,
  };
}

String labelFromStatus(String status) {
  return switch (status) {
    'placed' || 'pending' => 'Order placed',
    'picked_up' || 'at_shop' => 'Picked up',
    'sorted' || 'in_progress' => 'Sorted',
    'washing' || 'processing' => 'Washing',
    'out_for_delivery' || 'ready' || 'ready_for_pickup' => 'Ready',
    'delivered' || 'completed' => 'Delivered',
    'cancelled' => 'Cancelled',
    _ => status,
  };
}

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

/// Delivered orders for the Orders screen's Completed tab.
class CompletedOrdersNotifier extends Notifier<List<Order>> {
  @override
  List<Order> build() => [];

  Future<void> loadOrders() async {
    try {
      final data = await api.getOrders(status: 'delivered');
      state = data.map(orderFromJson).toList();
    } on ApiException {
      // Keep existing state on network errors
    }
  }
}

final completedOrdersProvider =
    NotifierProvider<CompletedOrdersNotifier, List<Order>>(CompletedOrdersNotifier.new);
