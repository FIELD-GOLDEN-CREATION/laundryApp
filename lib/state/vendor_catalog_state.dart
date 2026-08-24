import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vendor_mock_data.dart';

/// A single add-on service the vendor defines: title + price in TZS.
class VendorAddon {
  const VendorAddon({required this.title, required this.priceTzs});
  final String title;
  final double priceTzs;
}

class VendorCatalogState {
  const VendorCatalogState({
    this.categoriesOn = kDefaultCategoriesOn,
    this.prices = kDefaultVendorPrices,
    this.addons = const [
      VendorAddon(title: 'Delicate fabric treatment', priceTzs: 10400),
      VendorAddon(title: 'Stain removal (deep)', priceTzs: 16900),
      VendorAddon(title: 'Eco detergent', priceTzs: 3900),
      VendorAddon(title: 'Fabric softener & scent', priceTzs: 5200),
    ],
    this.itemsOn = const {},
    this.itemPrices = const {},
  });

  final List<bool> categoriesOn;
  final Map<String, double> prices;
  final List<VendorAddon> addons;

  /// Map of category ID -> list of item IDs that are enabled
  final Map<String, List<String>> itemsOn;

  /// Map of item ID -> price set by vendor
  final Map<String, double> itemPrices;

  VendorCatalogState copyWith({
    List<bool>? categoriesOn,
    Map<String, double>? prices,
    List<VendorAddon>? addons,
    Map<String, List<String>>? itemsOn,
    Map<String, double>? itemPrices,
  }) => VendorCatalogState(
    categoriesOn: categoriesOn ?? this.categoriesOn,
    prices: prices ?? this.prices,
    addons: addons ?? this.addons,
    itemsOn: itemsOn ?? this.itemsOn,
    itemPrices: itemPrices ?? this.itemPrices,
  );
}

/// Ports the source's `cats[]`/`vPrice{}` plus custom vendor add-ons.
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

  void addAddon(String title, double priceTzs) {
    state = state.copyWith(addons: [...state.addons, VendorAddon(title: title, priceTzs: priceTzs)]);
  }

  void removeAddon(int index) {
    final next = List<VendorAddon>.from(state.addons);
    if (index >= 0 && index < next.length) next.removeAt(index);
    state = state.copyWith(addons: next);
  }

  void updateAddon(int index, {String? title, double? priceTzs}) {
    final next = List<VendorAddon>.from(state.addons);
    if (index >= 0 && index < next.length) {
      next[index] = VendorAddon(
        title: title ?? next[index].title,
        priceTzs: priceTzs ?? next[index].priceTzs,
      );
      state = state.copyWith(addons: next);
    }
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
