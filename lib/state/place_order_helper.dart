import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../models/order_line.dart';
import '../utils/cart_math.dart';
import 'cart_addons_state.dart';
import 'cart_state.dart';
import 'catalog_state.dart' show shopAddonsProvider;
import 'fulfillment_state.dart';
import 'orders_state.dart';
import 'vendor_catalog_state.dart' show VendorAddon;

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

  // Add-ons the customer toggled on in the basket — resolved against the
  // same shop add-on list the cart screen showed the toggles against, since
  // `cartAddonsProvider` only tracks selected indices into that list.
  final vendorAddons = fulfillment.shopSlug.isEmpty
      ? const <VendorAddon>[]
      : ref.read(shopAddonsProvider(fulfillment.shopSlug)).asData?.value ?? const <VendorAddon>[];
  final cartAddonsNotifier = ref.read(cartAddonsProvider.notifier);
  final selectedAddons = cartAddonsNotifier.selected(vendorAddons);
  final apiAddons = [
    for (final a in selectedAddons)
      {
        'addon_id': int.tryParse(a.id ?? ''),
        'title': a.title,
        'price_tzs': a.priceTzs.round(),
      },
  ];

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
        addons: apiAddons,
        fulfillment: fulfillment.mode,
        paymentMethod: paymentMethod,
      );
      if (order != null) {
        // Clear cart after successful order
        ref.read(cartProvider.notifier).clear();
        cartAddonsNotifier.clear();
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
    lines: [
      ...cartLines(qty, [], priced),
      for (final a in selectedAddons) OrderLine(name: a.title, qty: 1, unitPrice: a.priceTzs),
    ],
    fulfillment: fulfillment.mode,
    deliveryFeeTzs: fulfillment.isDelivery ? fulfillment.deliveryFeeTzs : 0,
  );
  ref.read(cartProvider.notifier).clear();
  cartAddonsNotifier.clear();
  return order;
}
