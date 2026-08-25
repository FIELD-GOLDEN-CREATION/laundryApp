import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../utils/cart_math.dart';
import 'cart_state.dart';
import 'fulfillment_state.dart';
import 'orders_state.dart';

/// Places the current cart as a real order via the API.
/// Falls back to local-only placement if the API call fails.
Future<Order> placeCurrentOrder(
  WidgetRef ref, {
  required String paymentMethod,
  required String pickup,
  required String address,
  required String? total,
}) async {
  final qty = ref.read(cartProvider);
  final fulfillment = ref.read(fulfillmentProvider);
  final priced = fulfillment.pricedItems;
  final amount = total ?? formatMoney(cartSubtotal(qty, priced));

  // Build API items payload
  final apiItems = <Map<String, dynamic>>[];
  for (final item in priced) {
    final itemQty = qty[item.key] ?? 0;
    if (itemQty <= 0) continue;
    apiItems.add({
      'name': item.name,
      'qty': itemQty,
      'unit_price_tzs': item.price.toInt(),
      'line_type': 'item',
    });
  }

  // Try to place via API first
  if (apiItems.isNotEmpty && fulfillment.shopId.isNotEmpty) {
    try {
      final order = await ref.read(ordersProvider.notifier).createOrderApi(
        shopId: fulfillment.shopId,
        items: apiItems,
        fulfillment: fulfillment.mode,
        paymentMethod: paymentMethod,
      );
      if (order != null) {
        // Clear cart after successful order
        ref.read(cartProvider.notifier).clear();
        return order;
      }
    } catch (_) {
      // Fall through to local-only placement
    }
  }

  // Fallback: local-only placement (works offline or if API is unavailable)
  final order = ref.read(ordersProvider.notifier).placeOrder(
    shop: fulfillment.shop,
    items: '${cartItemCount(qty, priced)} items',
    total: amount,
    paymentMethod: paymentMethod,
    pickup: pickup,
    address: address,
    lines: cartLines(qty, [], priced),
    fulfillment: fulfillment.mode,
    driver: fulfillment.driver,
    deliveryFeeTzs: fulfillment.isDelivery ? fulfillment.deliveryFeeTzs : 0,
  );
  ref.read(cartProvider.notifier).clear();
  return order;
}
