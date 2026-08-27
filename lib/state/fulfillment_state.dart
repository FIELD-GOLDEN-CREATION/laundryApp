import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_item.dart';

class FulfillmentState {
  const FulfillmentState({
    this.mode = 'delivery',
    this.quoting = false,
    this.deliveryFeeTzs = 0,
    this.shop = '',
    this.extraItems = const {},
    this.catalog = const {},
    this.shopId = '',
  });

  final String mode;
  final bool quoting;
  final int deliveryFeeTzs;
  final String shop;

  /// Package/addon lines contributed by the shop screen.
  final Map<String, MenuItem> extraItems;

  /// Every priced item the customer can order at the current basket's shop —
  /// per-piece menu plus package/addon extras. Populated from API data by
  /// whichever screen fills the basket, so totals never depend on mock data.
  final Map<String, MenuItem> catalog;

  /// Backend id of the basket's shop (for order placement).
  final String shopId;

  /// Catalog including extras — what totals are computed over.
  List<MenuItem> get pricedItems => [...catalog.values, ...extraItems.values];

  bool get isDelivery => mode == 'delivery';

  FulfillmentState copyWith({
    String? mode,
    bool? quoting,
    int? deliveryFeeTzs,
    String? shop,
    Map<String, MenuItem>? extraItems,
    Map<String, MenuItem>? catalog,
    String? shopId,
  }) =>
      FulfillmentState(
        mode: mode ?? this.mode,
        quoting: quoting ?? this.quoting,
        deliveryFeeTzs: deliveryFeeTzs ?? this.deliveryFeeTzs,
        shop: shop ?? this.shop,
        extraItems: extraItems ?? this.extraItems,
        catalog: catalog ?? this.catalog,
        shopId: shopId ?? this.shopId,
      );
}

class FulfillmentNotifier extends Notifier<FulfillmentState> {
  @override
  FulfillmentState build() => const FulfillmentState();

  void setMode(String mode) => state = state.copyWith(
        mode: mode,
        deliveryFeeTzs: mode == 'delivery' ? state.deliveryFeeTzs : 0,
      );

  void setShop(String shop) => state = state.copyWith(shop: shop);

  /// Points the basket at [shop] (backend id [shopId], when known) and drops
  /// any non-catalog lines the previous vendor contributed. Callers are
  /// responsible for clearing `cartProvider` alongside it — `ensureBasketShop`
  /// does both.
  void startBasketFor(String shop, {String shopId = ''}) => state = state.copyWith(
        shop: shop,
        shopId: shopId,
        extraItems: const {},
        catalog: const {},
      );

  /// Registers the current basket's shop and its full price list (API data).
  void setShopCatalog({
    required String shopId,
    required String shopName,
    required List<MenuItem> items,
  }) =>
      state = state.copyWith(
        shopId: shopId,
        shop: shopName,
        catalog: {for (final item in items) item.key: item},
      );

  void addServiceItem(MenuItem item) => state = state.copyWith(
        extraItems: {...state.extraItems, item.key: item},
        catalog: {...state.catalog, item.key: item},
      );

  void setQuoting(bool quoting) => state = state.copyWith(quoting: quoting);

  void finishQuote({required int fee}) => state = state.copyWith(quoting: false, deliveryFeeTzs: fee);
}

final fulfillmentProvider = NotifierProvider<FulfillmentNotifier, FulfillmentState>(FulfillmentNotifier.new);
