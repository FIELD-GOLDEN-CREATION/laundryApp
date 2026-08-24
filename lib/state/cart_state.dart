import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_package.dart';

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

/// Tracks which package is currently in the cart. When a package is added,
/// its items are loaded into the cart as package items. Any items not part
/// of the package fall back to normal per-item pricing.
class CartPackageNotifier extends Notifier<ServicePackage?> {
  @override
  ServicePackage? build() => null;

  /// Adds a package to the cart. Its items are pre-loaded at their
  /// specified quantities.
  void addPackage(ServicePackage pkg, CartNotifier cart) {
    // Clear any previous package items from the cart
    final prev = state;
    if (prev != null) {
      for (final pi in prev.packageItems) {
        cart.setQty(pi.itemId, -pi.qty);
      }
    }
    // Add the new package's items
    for (final pi in pkg.packageItems) {
      cart.setQty(pi.itemId, pi.qty);
    }
    state = pkg;
  }

  /// Removes the current package from the cart.
  void removePackage(CartNotifier cart) {
    final pkg = state;
    if (pkg != null) {
      for (final pi in pkg.packageItems) {
        cart.setQty(pi.itemId, -pi.qty);
      }
    }
    state = null;
  }

  void clear() => state = null;
}

final cartPackageProvider = NotifierProvider<CartPackageNotifier, ServicePackage?>(CartPackageNotifier.new);
