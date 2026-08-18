import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vendor_mock_data.dart';

class VendorCatalogState {
  const VendorCatalogState({
    this.categoriesOn = kDefaultCategoriesOn,
    this.prices = kDefaultVendorPrices,
    this.turnaround = 1,
    this.addonsOn = kDefaultAddonsOn,
    this.itemsOn = const {},
    this.itemPrices = const {},
  });

  final List<bool> categoriesOn;
  final Map<String, double> prices;
  final int turnaround;
  final List<bool> addonsOn;
  
  /// Map of category ID -> list of item IDs that are enabled
  final Map<String, List<String>> itemsOn;
  
  /// Map of item ID -> price set by vendor
  final Map<String, double> itemPrices;

  VendorCatalogState copyWith({
    List<bool>? categoriesOn,
    Map<String, double>? prices,
    int? turnaround,
    List<bool>? addonsOn,
    Map<String, List<String>>? itemsOn,
    Map<String, double>? itemPrices,
  }) => VendorCatalogState(
    categoriesOn: categoriesOn ?? this.categoriesOn,
    prices: prices ?? this.prices,
    turnaround: turnaround ?? this.turnaround,
    addonsOn: addonsOn ?? this.addonsOn,
    itemsOn: itemsOn ?? this.itemsOn,
    itemPrices: itemPrices ?? this.itemPrices,
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

  void toggleItem(String categoryId, String itemId) {
    final nextItemsOn = Map<String, List<String>>.from(state.itemsOn);
    final currentItems = List<String>.from(nextItemsOn[categoryId] ?? []);
    
    if (currentItems.contains(itemId)) {
      currentItems.remove(itemId);
    } else {
      currentItems.add(itemId);
    }
    
    nextItemsOn[categoryId] = currentItems;
    state = state.copyWith(itemsOn: nextItemsOn);
  }

  void setItemPrice(String itemId, double price) {
    final nextItemPrices = Map<String, double>.from(state.itemPrices);
    nextItemPrices[itemId] = price.clamp(0, double.infinity);
    state = state.copyWith(itemPrices: nextItemPrices);
  }

  bool isItemEnabled(String categoryId, String itemId) {
    return state.itemsOn[categoryId]?.contains(itemId) ?? false;
  }

  double getItemPrice(String itemId) {
    return state.itemPrices[itemId] ?? 0;
  }
}

final vendorCatalogProvider = NotifierProvider<VendorCatalogNotifier, VendorCatalogState>(VendorCatalogNotifier.new);
