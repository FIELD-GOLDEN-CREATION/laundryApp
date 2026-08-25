import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../utils/cart_math.dart';
import 'cart_state.dart';
import 'fulfillment_state.dart';
import 'orders_state.dart';

Order placeCurrentOrder(
  WidgetRef ref, {
  required String paymentMethod,
  required String pickup,
  required String address,
  required String? total,
}) {
  final qty = ref.read(cartProvider);
  final fulfillment = ref.read(fulfillmentProvider);
  final priced = fulfillment.pricedItems;
  final amount = total ?? formatMoney(cartSubtotal(qty, priced));
  return ref.read(ordersProvider.notifier).placeOrder(
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
}