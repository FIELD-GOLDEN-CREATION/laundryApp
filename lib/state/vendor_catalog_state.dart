import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

class VendorAddon {
  const VendorAddon({required this.title, required this.priceTzs, this.id});
  final String title;
  final double priceTzs;
  final String? id;
}

class VendorCatalogState {
  const VendorCatalogState({
    this.categoriesOn = const {},
    this.prices = const {},
    this.addons = const [],
    this.itemsOn = const {},
    this.itemPrices = const {},
    this.vendorPrices = const {},
    this.itemAvailability = const {},
    this.isLoading = false,
  });

  /// categoryId → enabled. Defaults to true for every global category until
  /// GET /vendor/catalog says otherwise.
  final Map<String, bool> categoriesOn;

  /// Local price edits keyed by item id.
  final Map<String, double> prices;

  final List<VendorAddon> addons;

  /// categoryId → item ids explicitly toggled off/on locally.
  final Map<String, List<String>> itemsOn;

  /// Price edits keyed by item id.
  final Map<String, double> itemPrices;

  /// The vendor's own prices from GET /vendor/catalog (`vendor_items`).
  final Map<String, double> vendorPrices;

  /// The vendor's availability flags from GET /vendor/catalog.
  final Map<String, bool> itemAvailability;

  final bool isLoading;

  VendorCatalogState copyWith({
    Map<String, bool>? categoriesOn,
    Map<String, double>? prices,
    List<VendorAddon>? addons,
    Map<String, List<String>>? itemsOn,
    Map<String, double>? itemPrices,
    Map<String, double>? vendorPrices,
    Map<String, bool>? itemAvailability,
    bool? isLoading,
  }) =>
      VendorCatalogState(
        categoriesOn: categoriesOn ?? this.categoriesOn,
        prices: prices ?? this.prices,
        addons: addons ?? this.addons,
        itemsOn: itemsOn ?? this.itemsOn,
        itemPrices: itemPrices ?? this.itemPrices,
        vendorPrices: vendorPrices ?? this.vendorPrices,
        itemAvailability: itemAvailability ?? this.itemAvailability,
        isLoading: isLoading ?? this.isLoading,
      );
}

class VendorCatalogNotifier extends Notifier<VendorCatalogState> {
  @override
  VendorCatalogState build() => const VendorCatalogState();

  /// Loads the vendor's own price/availability overlays from
  /// GET /vendor/catalog. Category/item structure itself comes from the
  /// global catalog provider; only overrides live here.
  Future<void> loadCatalog() async {
    try {
      final rows = await api.getVendorCatalog();
      final vendorPrices = <String, double>{};
      final availability = <String, bool>{};
      final categoriesOn = <String, bool>{};

      for (final row in rows) {
        final categoryId = '${row['category_id'] ?? row['category']?['id'] ?? ''}';
        if (categoryId.isNotEmpty) {
          categoriesOn[categoryId] = row['is_enabled'] as bool? ?? true;
        }
        for (final j in (row['category']?['items'] as List?)
                ?.whereType<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[]) {
          final itemId = '${j['id'] ?? j['item_id'] ?? ''}';
          if (itemId.isEmpty) continue;
          final vp = j['vendor_price'] as num?;
          if (vp != null) vendorPrices[itemId] = vp.toDouble();
          final va = j['vendor_available'] as bool?;
          if (va != null) availability[itemId] = va;
        }
      }

      state = state.copyWith(
        vendorPrices: vendorPrices,
        itemAvailability: availability,
        categoriesOn: {...categoriesOn, ...state.categoriesOn},
      );
    } on ApiException {
      // Fall back to default prices from the global catalog.
    }
  }

  Future<void> loadAddons() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getVendorAddons();
      final addons = data.map((j) => VendorAddon(
        id: j['id'] as String?,
        title: j['name'] as String? ?? j['title'] as String? ?? '',
        priceTzs: (j['price'] as num?)?.toDouble()
            ?? (j['price_tzs'] as num?)?.toDouble()
            ?? 0,
      )).toList();
      state = state.copyWith(addons: addons, isLoading: false);
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> addAddon(String title, double priceTzs) async {
    try {
      final data = await api.createVendorAddon({'name': title, 'price': priceTzs});
      final j = data['data'] as Map<String, dynamic>? ?? data;
      final addon = VendorAddon(
        id: j['id'] as String?,
        title: title,
        priceTzs: priceTzs,
      );
      state = state.copyWith(addons: [...state.addons, addon]);
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> removeAddon(int index) async {
    final addon = state.addons[index];
    if (addon.id != null) {
      try {
        await api.deleteVendorAddon(addon.id!);
      } on ApiException {
        return false;
      }
    }
    final next = List<VendorAddon>.from(state.addons);
    if (index >= 0 && index < next.length) next.removeAt(index);
    state = state.copyWith(addons: next);
    return true;
  }

  Future<bool> updateAddon(int index, {String? title, double? priceTzs}) async {
    final addon = state.addons[index];
    final updatedTitle = title ?? addon.title;
    final updatedPrice = priceTzs ?? addon.priceTzs;

    if (addon.id != null) {
      try {
        await api.updateVendorAddon(addon.id!, {'name': updatedTitle, 'price': updatedPrice});
      } on ApiException {
        return false;
      }
    }

    final next = List<VendorAddon>.from(state.addons);
    if (index >= 0 && index < next.length) {
      next[index] = VendorAddon(
        id: addon.id,
        title: updatedTitle,
        priceTzs: updatedPrice,
      );
      state = state.copyWith(addons: next);
    }
    return true;
  }

  void toggleCategory(String categoryId) {
    final next = Map.of(state.categoriesOn);
    next[categoryId] = !(next[categoryId] ?? true);
    state = state.copyWith(categoriesOn: next);
    _persistCategories(next);
  }

  void setPrice(String key, double value) {
    final next = Map.of(state.prices);
    next[key] = value.clamp(0, double.infinity);
    state = state.copyWith(prices: next);
  }

  void toggleItem(String categoryId, String itemId) {
    final currentPrice = effectiveItemPrice(itemId);
    final currentlyOn = isItemEnabled(categoryId, itemId);

    final nextItemsOn = Map<String, List<String>>.from(state.itemsOn);
    final currentItems = List<String>.from(nextItemsOn[categoryId] ?? []);
    if (currentItems.contains(itemId)) {
      currentItems.remove(itemId);
    } else {
      currentItems.add(itemId);
    }
    nextItemsOn[categoryId] = currentItems;
    state = state.copyWith(itemsOn: nextItemsOn);

    // Persist as an availability flip so the customer side stops/starts
    // offering the item.
    _persistItems({
      'items': [
        {'item_id': int.tryParse(itemId), 'price_tzs': currentPrice.round(), 'is_available': !currentlyOn},
      ],
    });
  }

  void setItemPrice(String itemId, double price) {
    final nextItemPrices = Map<String, double>.from(state.itemPrices);
    nextItemPrices[itemId] = price.clamp(0, double.infinity);
    state = state.copyWith(itemPrices: nextItemPrices);
    _persistItems({
      'items': [
        {'item_id': int.tryParse(itemId), 'price_tzs': price.round(), 'is_available': isItemAvailable(itemId)},
      ],
    });
  }

  bool isCategoryEnabled(String categoryId) =>
      state.categoriesOn[categoryId] ?? true;

  bool isItemEnabled(String categoryId, String itemId) {
    if (state.itemsOn.containsKey(categoryId)) {
      return state.itemsOn[categoryId]!.contains(itemId);
    }
    return state.itemAvailability[itemId] ?? true;
  }

  bool isItemAvailable(String itemId) => state.itemAvailability[itemId] ?? true;

  /// The vendor's own price when known, else whatever local edit exists.
  double effectiveItemPrice(String itemId) =>
      state.itemPrices[itemId]
          ?? state.vendorPrices[itemId]
          ?? state.prices[itemId]
          ?? 0;

  Future<void> _persistCategories(Map<String, bool> categoriesOn) async {
    final payload = [
      for (final e in categoriesOn.entries)
        if (int.tryParse(e.key) != null)
          {'category_id': int.parse(e.key), 'is_enabled': e.value},
    ];
    if (payload.isEmpty) return;
    try {
      await api.updateVendorCatalog({'categories': payload});
    } on ApiException {
      // Keep the local toggle; it resyncs on next load.
    }
  }

  Future<void> _persistItems(Map<String, dynamic> payload) async {
    try {
      await api.updateVendorCatalog(payload);
    } on ApiException {
      // Keep the local edit; it resyncs on next load.
    }
  }
}

final vendorCatalogProvider = NotifierProvider<VendorCatalogNotifier, VendorCatalogState>(VendorCatalogNotifier.new);
