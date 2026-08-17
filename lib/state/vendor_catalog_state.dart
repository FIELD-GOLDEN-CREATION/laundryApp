import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vendor_mock_data.dart';

class VendorCatalogState {
  const VendorCatalogState({
    this.categoriesOn = kDefaultCategoriesOn,
    this.prices = kDefaultVendorPrices,
    this.turnaround = 1,
    this.addonsOn = kDefaultAddonsOn,
  });

  final List<bool> categoriesOn;
  final Map<String, double> prices;
  final int turnaround;
  final List<bool> addonsOn;

  VendorCatalogState copyWith({
    List<bool>? categoriesOn,
    Map<String, double>? prices,
    int? turnaround,
    List<bool>? addonsOn,
  }) => VendorCatalogState(
    categoriesOn: categoriesOn ?? this.categoriesOn,
    prices: prices ?? this.prices,
    turnaround: turnaround ?? this.turnaround,
    addonsOn: addonsOn ?? this.addonsOn,
  );
}

/// Ports the source's `cats[]`/`vPrice{}`/`turn`/`addonsOn[]`.
class VendorCatalogNotifier extends Notifier<VendorCatalogState> {
  @override
  VendorCatalogState build() => const VendorCatalogState();

  void toggleCategory(int i) {
    final next = List.of(state.categoriesOn);
    next[i] = !next[i];
    state = state.copyWith(categoriesOn: next);
  }

  void setPrice(String key, double value) {
    final next = Map.of(state.prices);
    next[key] = value.clamp(0, double.infinity);
    state = state.copyWith(prices: next);
  }

  void pickTurnaround(int i) => state = state.copyWith(turnaround: i);

  void toggleAddon(int i) {
    final next = List.of(state.addonsOn);
    next[i] = !next[i];
    state = state.copyWith(addonsOn: next);
  }
}

final vendorCatalogProvider = NotifierProvider<VendorCatalogNotifier, VendorCatalogState>(VendorCatalogNotifier.new);
