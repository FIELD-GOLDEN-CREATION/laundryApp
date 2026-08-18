import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/state/cart_state.dart';
import 'package:laundry_app/state/chat_state.dart';
import 'package:laundry_app/models/order.dart';
import 'package:laundry_app/state/checkout_state.dart';
import 'package:laundry_app/state/orders_state.dart';

void main() {
  test('CartNotifier.setQty increments and clamps at zero', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(cartProvider.notifier).setQty('shirt', 1);
    expect(container.read(cartProvider)['shirt'], 1);

    container.read(cartProvider.notifier).setQty('bed', -5);
    expect(container.read(cartProvider)['bed'], 0);
  });

  test('OrdersNotifier.placeOrder inserts an unpicked-up order at the top', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(ordersProvider).length;
    final placed = container.read(
      ordersProvider.notifier,
    ).placeOrder(shop: 'Marina Fresh Laundry', items: '4 items', total: 'TZS 1,000');

    final orders = container.read(ordersProvider);
    expect(orders.length, before + 1);
    expect(orders.first.id, placed.id);
    expect(orders.first.trackStep, kOrderPlacedStep);
  });

  test('OrdersNotifier.advanceStep cycles a specific order placed..3..placed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(ordersProvider.notifier);
    final placed = notifier.placeOrder(shop: 'Marina Fresh Laundry', items: '4 items', total: 'TZS 1,000');

    Order current() => container.read(ordersProvider).firstWhere((o) => o.id == placed.id);

    notifier.advanceStep(placed.id);
    expect(current().trackStep, 0);
    notifier.advanceStep(placed.id);
    notifier.advanceStep(placed.id);
    notifier.advanceStep(placed.id);
    expect(current().trackStep, 3);
    notifier.advanceStep(placed.id);
    expect(current().trackStep, kOrderPlacedStep);
  });

  test('ChatNotifier.send appends a message and clears the draft', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(chatProvider.notifier).setDraft('  Thanks!  ');
    container.read(chatProvider.notifier).send('Marina Fresh Laundry');

    final state = container.read(chatProvider);
    expect(state.draft, '');
    expect(state.messagesFor('Marina Fresh Laundry').last.text, 'Thanks!');
    expect(state.messagesFor('Marina Fresh Laundry').last.isMe, isTrue);
  });

  test('ChatNotifier.send ignores an empty draft', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(chatProvider).messagesFor('Marina Fresh Laundry').length;
    container.read(chatProvider.notifier).setDraft('   ');
    container.read(chatProvider.notifier).send('Marina Fresh Laundry');

    expect(container.read(chatProvider).messagesFor('Marina Fresh Laundry').length, before);
  });

  test('discountFor only applies once a promo code is entered', () {
    expect(discountFor(''), 0.0);
    expect(discountFor('SAVE4'), 10400.0);
  });
}
