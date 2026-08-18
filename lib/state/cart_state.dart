import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Item key -> quantity. Ports the source's `state.qty` + `setQty`. Starts
/// empty — the basket only fills as the customer taps "+" on menu items.
class CartNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {};

  void setQty(String key, int delta) {
    final next = Map.of(state);
    next[key] = ((next[key] ?? 0) + delta).clamp(0, 999);
    state = next;
  }

  /// Empties the basket — used when the customer starts an order at a
  /// different vendor (see `widgets/basket_shop_guard.dart`).
  void clear() => state = {};
}

final cartProvider = NotifierProvider<CartNotifier, Map<String, int>>(CartNotifier.new);
