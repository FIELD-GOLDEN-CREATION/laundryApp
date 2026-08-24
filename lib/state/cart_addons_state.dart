import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/vendor_catalog_state.dart';

/// Tracks which add-on services the customer has toggled in their basket.
/// The vendor defines the available add-ons in [VendorCatalogState.addons];
/// this state mirrors them and tracks the customer's selections.
class CartAddonsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int index) {
    final next = Set<int>.from(state);
    if (next.contains(index)) {
      next.remove(index);
    } else {
      next.add(index);
    }
    state = next;
  }

  /// Returns the total price of all toggled add-ons.
  double totalFor(List<VendorAddon> addons) {
    var sum = 0.0;
    for (final i in state) {
      if (i < addons.length) sum += addons[i].priceTzs;
    }
    return sum;
  }

  /// Returns just the selected addons with their details.
  List<VendorAddon> selected(List<VendorAddon> addons) {
    final result = <VendorAddon>[];
    for (final i in state) {
      if (i < addons.length) result.add(addons[i]);
    }
    return result;
  }

  void clear() => state = {};
}

final cartAddonsProvider = NotifierProvider<CartAddonsNotifier, Set<int>>(CartAddonsNotifier.new);
