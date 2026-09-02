import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../models/order_line.dart';
import '../utils/cart_math.dart';
import 'catalog_state.dart' show shopAddonsProvider;
import 'orders_state.dart';
import 'vendor_basket.dart';
import 'vendor_catalog_state.dart' show VendorAddon;

/// Places [shopId]'s current basket as a real order via the API.
/// Falls back to local-only placement if the API call fails. Only ever
/// touches [shopId]'s own basket entry — every other vendor's in-progress
/// basket is left completely untouched, before and after.
Future<Order> placeCurrentOrder(
  WidgetRef ref, {
  required String shopId,
  required String paymentMethod,
  required String pickup,
  required String address,
  required String? total,
  String? promoCode,
  double? deliveryLat,
  double? deliveryLng,
}) async {
  final basket = ref.read(basketsProvider)[shopId] ?? VendorBasket.empty(shopId);
  final qty = basket.qty;
  final priced = basket.pricedItems;
  final amount = total ?? formatMoney(cartSubtotal(qty, priced));

  // Add-ons the customer toggled on in the basket — resolved against the
  // same shop add-on list the cart screen showed the toggles against, since
  // `VendorBasket.selectedAddonIndices` only tracks selected indices into
  // that list.
  final vendorAddons = basket.shopSlug.isEmpty
      ? const <VendorAddon>[]
      : ref.read(shopAddonsProvider(basket.shopSlug)).asData?.value ?? const <VendorAddon>[];
  final selected = selectedAddons(basket.selectedAddonIndices, vendorAddons);
  final apiAddons = [
    for (final a in selected)
      {
        'addon_id': int.tryParse(a.id ?? ''),
        'title': a.title,
        'price_tzs': a.priceTzs.round(),
      },
  ];

  // Build API items payload. `item_id` is the real catalog id behind each
  // line's key — needed server-side to re-price a category/item-scoped
  // promo against just the matching line(s), the same way `/promos/validate`
  // already does from the cart.
  final apiItems = <Map<String, dynamic>>[];
  for (final item in priced) {
    final itemQty = qty[item.key] ?? 0;
    if (itemQty <= 0) continue;
    // A package line's key is `pkg:<shopId>:<packageId>` (see
    // `ServicePackage.cartKey`) — tag it as a bundle sale rather than a
    // generic item line, per the order endpoint's validated contract, and
    // carry the real package id so it's recorded against the right bundle.
    final isPackageLine = item.key.startsWith('pkg:');
    apiItems.add({
      'item_id': isPackageLine ? null : int.tryParse(item.key.split(':').last),
      'name': item.name,
      'qty': itemQty,
      'unit_price_tzs': item.price.toInt(),
      'line_type': isPackageLine ? 'package' : 'item',
      if (isPackageLine) 'package_id': int.tryParse(item.key.split(':').last),
    });
  }

  // Try to place via API first
  if (apiItems.isNotEmpty && shopId.isNotEmpty) {
    try {
      final order = await ref.read(ordersProvider.notifier).createOrderApi(
        shopId: shopId,
        items: apiItems,
        addons: apiAddons,
        fulfillment: basket.mode,
        paymentMethod: paymentMethod,
        promoCode: promoCode,
        packageId: cartPackageId(qty, priced),
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
      );
      if (order != null) {
        ref.read(basketsProvider.notifier).clearBasket(shopId);
        return order;
      }
    } catch (_) {
      // Fall through to local-only placement
    }
  }

  // Fallback: local-only placement (works offline or if API is unavailable)
  final order = ref.read(ordersProvider.notifier).placeOrder(
    shop: basket.shopName,
    items: '${cartItemCount(qty, priced)} items',
    total: amount,
    paymentMethod: paymentMethod,
    pickup: pickup,
    address: address,
    lines: [
      ...cartLines(qty, [], priced),
      for (final a in selected) OrderLine(name: a.title, qty: 1, unitPrice: a.priceTzs),
    ],
    fulfillment: basket.mode,
    deliveryFeeTzs: basket.isDelivery ? basket.deliveryFeeTzs : 0,
  );
  ref.read(basketsProvider.notifier).clearBasket(shopId);
  return order;
}
