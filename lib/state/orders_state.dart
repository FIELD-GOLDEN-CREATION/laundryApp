import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../models/order_line.dart';
import '../models/order_tracking_event.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';

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
    List<Map<String, dynamic>>? addons,
    String fulfillment = 'delivery',
    String? addressId,
    String? scheduledDate,
    String? scheduledTimeSlot,
    String? promoCode,
    String? packageId,
    double? deliveryLat,
    double? deliveryLng,
    String? paymentMethod,
    String? paymentToken,
  }) async {
    try {
      final data = await api.createOrder({
        'shop_id': shopId,
        'items': items,
        if (addons != null && addons.isNotEmpty) 'addons': addons,
        'fulfillment': fulfillment,
        if (addressId != null) 'address_id': addressId,
        if (scheduledDate != null) 'scheduled_date': scheduledDate,
        if (scheduledTimeSlot != null) 'scheduled_time_slot': scheduledTimeSlot,
        if (promoCode != null) 'promo_code': promoCode,
        if (packageId != null) 'package_id': packageId,
        // Same coordinates the pre-order quote used, so the fee charged
        // here matches what was shown on the Schedule screen instead of
        // silently falling back to a flat estimate.
        if (deliveryLat != null) 'delivery_lat': deliveryLat,
        if (deliveryLng != null) 'delivery_lng': deliveryLng,
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

  /// Reflects a review create/edit/delete (`review: null`) immediately in
  /// this list without a full reload; a no-op if `id` isn't in this list.
  void setReview(String id, Review? review) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWithReview(review) else o,
    ];
  }
}

Order orderFromJson(Map<String, dynamic> j) {
  final statusStr = j['status'] as String? ?? 'placed';
  final fulfillment = j['fulfillment'] as String? ?? 'delivery';
  final step = stepFromStatus(statusStr, fulfillment);
  final colors = orderStatusForStep(step);

  // Backend returns 'lines' (not 'items') with 'qty' and 'unit_price_tzs'
  final rawLines = j['lines'] as List? ?? j['items'] as List? ?? [];
  final lines = rawLines.map((l) => OrderLine(
    name: l['name'] as String? ?? '',
    qty: (l['quantity'] ?? l['qty'] ?? 1) as int,
    unitPrice: parseDouble(l['price'] ?? l['unit_price_tzs']) ?? 0,
  )).toList();

  // Backend nests shop as an object; extract the name
  final shopData = j['shop'];
  final shopName = shopData is Map<String, dynamic>
      ? shopData['name'] as String? ?? ''
      : j['shop_name'] as String? ?? j['shop'] as String? ?? '';

  // Backend uses 'total_tzs' (decimal string), fallback to 'total'
  final totalVal = parseDouble(j['total_tzs'] ?? j['total']) ?? 0;

  // Items summary
  final itemsSummary = j['items_summary'] as String? ??
      (lines.isEmpty ? '0 items' : '${lines.length} item${lines.length == 1 ? '' : 's'}');

  final tracking = (j['tracking'] as List? ?? [])
      .whereType<Map<String, dynamic>>()
      .map((t) => OrderTrackingEvent(
            status: t['status'] as String? ?? '',
            title: t['title'] as String? ?? '',
            completedAt: DateTime.tryParse((t['completed_at'] ?? t['created_at'] ?? '') as String? ?? ''),
          ))
      .toList();

  return Order(
    shop: shopName,
    id: j['id'] != null ? '#LD-${j['id']}' : (j['order_number'] as String? ?? ''),
    items: itemsSummary,
    status: labelFromStatus(statusStr),
    statusFg: colors.fg,
    statusBg: colors.bg,
    date: j['created_at'] as String? ?? '',
    total: 'TZS ${totalVal.toInt()}',
    trackStep: step,
    paymentMethod: j['payment_method'] as String? ?? '',
    pickup: j['pickup_time'] as String? ?? j['pickup_address'] as String? ?? '',
    address: j['delivery_address'] as String? ?? '',
    lines: lines,
    fulfillment: fulfillment,
    driver: j['driver_name'] as String? ?? '',
    deliveryFeeTzs: parseInt(j['delivery_fee'] ?? j['delivery_fee_tzs']) ?? 0,
    customerName: j['customer_name'] as String? ?? '',
    customerPhone: j['customer_phone'] as String? ?? '',
    tracking: tracking,
    review: orderReviewFromJson(j['review'] as Map<String, dynamic>?),
  );
}

/// Backend `orders.status` pipeline, in order — index i is what
/// `orderStatusForStep`/`selfOrderStatusForStep`'s case i describes. Mirrors
/// `VendorOrderController`'s status column (`pending` is pre-acceptance and
/// has no step; `cancelled` is a terminal branch, not a step).
const kOrderStatusSteps = ['accepted', 'in_wash', 'ready', 'out_for_delivery', 'delivered'];

int stepFromStatus(String status, String fulfillment) {
  final i = kOrderStatusSteps.indexOf(status);
  return i < 0 ? kOrderPlacedStep : i;
}

String labelFromStatus(String status) {
  return switch (status) {
    'pending' => 'Order placed',
    'accepted' => 'Accepted',
    'in_wash' => 'Washing',
    'ready' => 'Ready',
    'out_for_delivery' => 'Out for delivery',
    'delivered' => 'Delivered',
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

  /// Reflects a review create/edit/delete (`review: null`) immediately in
  /// this list without a full reload; a no-op if `id` isn't in this list.
  void setReview(String id, Review? review) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWithReview(review) else o,
    ];
  }
}

final completedOrdersProvider =
    NotifierProvider<CompletedOrdersNotifier, List<Order>>(CompletedOrdersNotifier.new);
