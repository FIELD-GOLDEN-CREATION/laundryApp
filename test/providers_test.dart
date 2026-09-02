import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:laundry_app/models/order.dart';
import 'package:laundry_app/state/chat_state.dart';
import 'package:laundry_app/state/orders_state.dart';
import 'package:laundry_app/state/vendor_basket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  test('BasketsNotifier.setQty increments and clamps at zero', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(basketsProvider.notifier).setQty('shop-a', 'shirt', 1);
    expect(container.read(basketsProvider)['shop-a']?.qty['shirt'], 1);

    container.read(basketsProvider.notifier).setQty('shop-a', 'bed', -5);
    expect(container.read(basketsProvider)['shop-a']?.qty['bed'], 0);
  });

  test('BasketsNotifier.setQty applies deltas and clamps at zero', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(basketsProvider.notifier);
    notifier.setQty('shop-a', 'shirt', 5);
    expect(container.read(basketsProvider)['shop-a']?.qty['shirt'], 5);

    notifier.setQty('shop-a', 'shirt', -100);
    expect(container.read(basketsProvider)['shop-a']?.qty['shirt'], 0);
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

  test('ChatNotifier.send appends a message and clears the draft', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(chatProvider.notifier).setDraft('  Thanks!  ');
    await container.read(chatProvider.notifier).send('Marina Fresh Laundry');

    final state = container.read(chatProvider);
    expect(state.draft, '');
    expect(state.messagesFor('Marina Fresh Laundry').last.text, 'Thanks!');
    expect(state.messagesFor('Marina Fresh Laundry').last.isMe, isTrue);
  });

  test('ChatNotifier.send ignores an empty draft', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = container.read(chatProvider).messagesFor('Marina Fresh Laundry').length;
    container.read(chatProvider.notifier).setDraft('   ');
    await container.read(chatProvider.notifier).send('Marina Fresh Laundry');

    expect(container.read(chatProvider).messagesFor('Marina Fresh Laundry').length, before);
  });
}
