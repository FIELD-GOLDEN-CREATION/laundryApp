import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_item.dart';

class FulfillmentState {
  const FulfillmentState({
    this.mode = 'delivery',
    this.quoting = false,
    this.deliveryFeeTzs = 0,
    this.driver = '',
    this.shop = 'Marina Fresh Laundry',
    this.extraItems = const {},
  });

  final String mode;
  final bool quoting;
  final int deliveryFeeTzs;
  final String driver;
  final String shop;

  final Map<String, MenuItem> extraItems;

  bool get isDelivery => mode == 'delivery';

  FulfillmentState copyWith({
    String? mode,
    bool? quoting,
    int? deliveryFeeTzs,
    String? driver,
    String? shop,
    Map<String, MenuItem>? extraItems,
  }) =>
      FulfillmentState(
        mode: mode ?? this.mode,
        quoting: quoting ?? this.quoting,
        deliveryFeeTzs: deliveryFeeTzs ?? this.deliveryFeeTzs,
        driver: driver ?? this.driver,
        shop: shop ?? this.shop,
        extraItems: extraItems ?? this.extraItems,
      );
}

class FulfillmentNotifier extends Notifier<FulfillmentState> {
  @override
  FulfillmentState build() => const FulfillmentState();

  void setMode(String mode) => state = state.copyWith(
        mode: mode,
        deliveryFeeTzs: mode == 'delivery' ? state.deliveryFeeTzs : 0,
        driver: mode == 'delivery' ? state.driver : '',
      );

  void setShop(String shop) => state = state.copyWith(shop: shop);

  /// Points the basket at [shop] and drops any non-catalog lines the
  /// previous vendor contributed. Callers are responsible for clearing
  /// `cartProvider` alongside it — `ensureBasketShop` does both.
  void startBasketFor(String shop) => state = state.copyWith(shop: shop, extraItems: const {});

  void addServiceItem(MenuItem item) =>
      state = state.copyWith(extraItems: {...state.extraItems, item.key: item});

  void setQuoting(bool quoting) => state = state.copyWith(quoting: quoting);

  void finishQuote({required int fee, required String driver}) =>
      state = state.copyWith(quoting: false, deliveryFeeTzs: fee, driver: driver);
}

final fulfillmentProvider = NotifierProvider<FulfillmentNotifier, FulfillmentState>(FulfillmentNotifier.new);

const kNearbyDrivers = ['Daniel O.', 'Kofi A.', 'Grace M.', 'Nadia H.'];

int deliveryFeeFor(int seed) => 1800 + (seed % 4) * 900;

String nearestDriverFor(int seed) => kNearbyDrivers[seed % kNearbyDrivers.length];
