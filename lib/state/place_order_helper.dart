import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/order.dart';
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
  final extra = fulfillment.extraItems.values.toList();
  final amount = total ?? formatMoney(cartSubtotal(qty, extra));
  return ref.read(ordersProvider.notifier).placeOrder(
    shop: fulfillment.shop,
    items: '${cartItemCount(qty, extra)} items',
    total: amount,
    paymentMethod: paymentMethod,
    pickup: pickup,
    address: address,
    lines: cartLines(qty, extra),
    fulfillment: fulfillment.mode,
    driver: fulfillment.driver,
    deliveryFeeTzs: fulfillment.isDelivery ? fulfillment.deliveryFeeTzs : 0,
  );
}