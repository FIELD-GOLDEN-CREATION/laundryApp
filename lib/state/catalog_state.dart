import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/laundry_category.dart';
import '../models/menu_item.dart';
import '../models/promo_offer.dart';
import '../models/review_item.dart';
import '../models/service_package.dart';
import '../models/shop.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';

// ── JSON → model mappers shared by every catalog screen ─────────────────

Shop shopFromJson(Map<String, dynamic> j) {
  final lat = double.tryParse('${j['latitude'] ?? ''}');
  final lng = double.tryParse('${j['longitude'] ?? ''}');
  final open = j['open_time'] as String?;
  final close = j['close_time'] as String?;
  final is24h = j['is_24h'] as bool? ?? false;

  return Shop(
    slotId: '${j['id']}',
    listSlotId: '${j['slug'] ?? j['id']}',
    name: j['name'] as String? ?? '',
    rating: (parseNum(j['rating_avg'])?.toDouble() ?? 0).toStringAsFixed(1),
    meta: (j['services'] as List?)?.isNotEmpty == true
        ? (j['services'][0]['name'] as String? ?? '')
        : (j['address'] as String? ?? ''),
    price: '',
    badge: j['badge'] as String? ?? '',
    reviewCount: '${j['rating_count'] ?? 0}',
    distance: '',
    hours: is24h
        ? 'Open 24 hours'
        : open != null && close != null
            ? 'Open till $close'
            : '',
    description: j['description'] as String? ?? '',
    badges: [
      if (is24h) '24h turnaround',
      ...(j['services'] as List?)?.map((s) => s['name'] as String? ?? '').where((s) => s.isNotEmpty) ?? <String>[],
    ],
    services: (j['services'] as List?)?.map((s) => s['name'] as String? ?? '').toList() ?? [],
    ratingValue: parseNum(j['rating_avg'])?.toDouble() ?? 0,
    priceFromTzs: 0,
    distanceKm: _distanceKm(lat, lng),
    is24h: is24h,
    isOpenNow: j['is_open'] as bool? ?? true,
    phone: j['phone'] as String? ?? '',
    imageUrl: j['image_url'] as String? ?? '',
  );
}

/// Rough straight-line distance from a Dar es Salaam reference point
/// (Masaki). Real GPS distance needs a location plugin — out of scope here.
double _distanceKm(double? lat, double? lng) {
  if (lat == null || lng == null) return 0;
  const refLat = -6.7903;
  const refLng = 39.2118;
  final dLat = (lat - refLat) * 110.574;
  final dLng = (lng - refLng) * 111.320;
  return double.parse(math.sqrt(dLat * dLat + dLng * dLng).toStringAsFixed(1));
}

PromoOffer promoFromJson(Map<String, dynamic> j) {
  PromoAppliesTo appliesTo = PromoAppliesTo.entireOrder;
  switch (j['applies_to'] as String?) {
    case 'specificCategory':
      appliesTo = PromoAppliesTo.specificCategory;
    case 'specificItem':
      appliesTo = PromoAppliesTo.specificItem;
  }

  return PromoOffer(
    id: '${j['id']}',
    code: j['code'] as String? ?? '',
    title: j['title'] as String? ?? '',
    description: j['description'] as String? ?? '',
    discountValue: parseNum(j['discount_value'])?.toDouble() ?? 0,
    isPercentage: j['is_percentage'] as bool? ?? false,
    expiresAt: DateTime.tryParse(j['expires_at'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 30)),
    imageUrl: '',
    vendorName: j['shop'] != null ? j['shop']['name'] as String? ?? '' : 'FreshFold',
    vendorId: j['shop_id'] != null ? '${j['shop_id']}' : null,
    minSpend: parseNum(j['min_spend_tzs'])?.toDouble() ?? 0,
    appliesTo: appliesTo,
    targetCategory: j['target_category_id'] != null ? '${j['target_category_id']}' : null,
    targetItem: j['target_item_id'] != null ? '${j['target_item_id']}' : null,
    maxRedemptions: parseNum(j['max_redemptions'])?.toInt(),
    currentRedemptions: parseNum(j['redemptions_count'])?.toInt() ?? 0,
    isActive: j['is_active'] as bool? ?? true,
  );
}

LaundryCategory categoryFromJson(Map<String, dynamic> j, [List<LaundryItem> items = const []]) {
  return LaundryCategory(
    id: '${j['id']}',
    name: j['name'] as String? ?? '',
    nameSwahili: j['name_swahili'] as String? ?? '',
    description: j['description'] as String? ?? '',
    imageUrl: j['image_url'] as String? ?? '',
    items: items,
  );
}

LaundryItem itemFromJson(Map<String, dynamic> j) {
  return LaundryItem(
    id: '${j['id'] ?? j['item_id'] ?? ''}',
    name: j['name'] as String? ?? (j['item'] as Map<String, dynamic>?)?['name'] as String? ?? '',
    nameSwahili: j['name_swahili'] as String? ?? '',
    description: j['description'] as String? ?? '',
    imageUrl: j['image_url'] as String? ?? '',
    priceTzs: parseNum(j['price_tzs'])?.toDouble() ??
        parseNum(j['vendor_price'])?.toDouble() ??
        parseNum(j['default_price_tzs'])?.toDouble() ??
        0,
    unit: j['unit'] as String? ?? 'per piece',
    isAvailable: j['is_available'] as bool? ?? true,
  );
}

ServicePackage packageFromJson(Map<String, dynamic> j) {
  final kindStr = j['kind'] as String? ?? 'weight';
  final kind = switch (kindStr) {
    'item_count' => PackageKind.itemCount,
    'household' => PackageKind.household,
    'subscription' => PackageKind.subscription,
    _ => PackageKind.weight,
  };

  final shop = j['shop'] as Map<String, dynamic>?;

  return ServicePackage(
    id: '${j['id']}',
    shopId: '${j['shop_id'] ?? shop?['id'] ?? ''}',
    shopName: shop?['name'] as String? ?? '',
    name: j['name'] as String? ?? '',
    tagline: j['tagline'] as String? ?? '',
    kind: kind,
    priceTzs: parseNum(j['price_tzs'])?.toDouble() ?? 0,
    priceUnit: j['price_unit'] as String? ?? '/ bag',
    inclusions: (j['inclusions'] as List?)
            ?.map((e) => e is Map<String, dynamic> ? e['label'] as String? ?? '' : '$e')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [],
    compareAtTzs: parseNum(j['compare_at_tzs'])?.toDouble(),
    note: j['note'] as String? ?? '',
    tag: j['tag'] as String? ?? '',
    serviceTags: (j['service_tags'] as List?)
            ?.map((e) => e is Map<String, dynamic> ? e['service_name'] as String? ?? '' : '$e')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [],
    active: j['is_active'] as bool? ?? true,
    packageItems: (j['items'] as List?)
            ?.map((e) {
              if (e is! Map<String, dynamic>) return null;
              final item = e['item'] as Map<String, dynamic>?;
              return PackageItem(
                itemId: '${e['item_id'] ?? item?['id'] ?? ''}',
                itemName: item?['name'] as String? ?? e['name'] as String? ?? '',
                qty: parseNum(e['qty'])?.toInt() ?? 0,
                unitPrice: parseDouble(item?['default_price_tzs']) ?? 0,
              );
            })
            .whereType<PackageItem>()
            .toList() ??
        [],
  );
}

ReviewItem reviewFromJson(Map<String, dynamic> j) {
  final rating = parseDouble(j['rating']) ?? 5;
  final customer = j['customer'] as Map<String, dynamic>?;
  return ReviewItem(
    name: customer?['name'] as String? ?? 'Customer',
    stars: '★' * rating.round(),
    text: j['comment'] as String? ?? '',
  );
}

// ── Providers ────────────────────────────────────────────────────────────

class AsyncCatalogState<T> {
  const AsyncCatalogState({this.items = const [], this.isLoading = false});
  final List<T> items;
  final bool isLoading;

  AsyncCatalogState<T> copyWith({List<T>? items, bool? isLoading}) =>
      AsyncCatalogState(items: items ?? this.items, isLoading: isLoading ?? this.isLoading);
}

class ShopsNotifier extends Notifier<AsyncCatalogState<Shop>> {
  @override
  AsyncCatalogState<Shop> build() => const AsyncCatalogState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getShops();
      state = AsyncCatalogState(items: data.map(shopFromJson).toList());
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }
}

final shopsProvider =
    NotifierProvider<ShopsNotifier, AsyncCatalogState<Shop>>(ShopsNotifier.new);

class OffersNotifier extends Notifier<AsyncCatalogState<PromoOffer>> {
  @override
  AsyncCatalogState<PromoOffer> build() => const AsyncCatalogState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getPromos();
      state = AsyncCatalogState(items: data.map(promoFromJson).toList());
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }
}

final offersProvider =
    NotifierProvider<OffersNotifier, AsyncCatalogState<PromoOffer>>(OffersNotifier.new);

class CategoriesNotifier extends Notifier<AsyncCatalogState<LaundryCategory>> {
  @override
  AsyncCatalogState<LaundryCategory> build() => const AsyncCatalogState();

  Future<void> load({bool withItems = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getCategories();
      final categories = <LaundryCategory>[];
      for (final j in data) {
        var items = <LaundryItem>[];
        if (withItems) {
          try {
            final itemData = await api.getItems('${j['id']}');
            items = itemData.map(itemFromJson).toList();
          } on ApiException {
            // Category without items still renders.
          }
        }
        categories.add(categoryFromJson(j, items));
      }
      state = AsyncCatalogState(items: categories);
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }
}

final categoriesProvider =
    NotifierProvider<CategoriesNotifier, AsyncCatalogState<LaundryCategory>>(CategoriesNotifier.new);

class PopularPackagesNotifier extends Notifier<AsyncCatalogState<ServicePackage>> {
  @override
  AsyncCatalogState<ServicePackage> build() => const AsyncCatalogState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getAllPackages();
      // One package per shop keeps the carousel varied.
      final seenShops = <String>{};
      final picked = <ServicePackage>[];
      for (final j in data) {
        final shopId = '${j['shop_id']}';
        if (seenShops.add(shopId)) {
          picked.add(packageFromJson(j));
        }
      }
      state = AsyncCatalogState(items: picked.take(6).toList());
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }
}

final popularPackagesProvider =
    NotifierProvider<PopularPackagesNotifier, AsyncCatalogState<ServicePackage>>(PopularPackagesNotifier.new);

class ReviewsNotifier extends Notifier<AsyncCatalogState<ReviewItem>> {
  @override
  AsyncCatalogState<ReviewItem> build() => const AsyncCatalogState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getReviews();
      state = AsyncCatalogState(items: data.map(reviewFromJson).take(6).toList());
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }
}

final reviewsProvider =
    NotifierProvider<ReviewsNotifier, AsyncCatalogState<ReviewItem>>(ReviewsNotifier.new);

/// Cheapest vendor offer for one item, from GET /items/{id}/offers.
class ItemOffer {
  const ItemOffer({
    required this.shopId,
    required this.shopName,
    required this.shopSlug,
    required this.imageUrl,
    required this.priceTzs,
  });

  final String shopId;
  final String shopName;
  final String shopSlug;
  final String imageUrl;
  final double priceTzs;
}

class ItemOffersNotifier extends Notifier<Map<String, ItemOffer>> {
  @override
  Map<String, ItemOffer> build() => {};

  Future<void> loadFor(String itemId) async {
    if (state.containsKey(itemId)) return;
    try {
      final data = await api.getItemOffers(itemId);
      final offers = ((data['data'] ?? data)['offers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (offers.isEmpty) return;
      final best = offers.first;
      state = {
        ...state,
        itemId: ItemOffer(
          shopId: '${best['shop_id'] ?? ''}',
          shopName: best['shop_name'] as String? ?? '',
          shopSlug: best['shop_slug'] as String? ?? '',
          imageUrl: best['image_url'] as String? ?? '',
          priceTzs: parseDouble(best['price_tzs']) ?? 0,
        ),
      };
    } on ApiException {
      // Leave the item without a vendor callout.
    }
  }
}

final itemOffersProvider =
    NotifierProvider<ItemOffersNotifier, Map<String, ItemOffer>>(ItemOffersNotifier.new);

/// One vendor's real starting price for items in a given category, from
/// GET /categories/{id}/shops — the mirror image of [ItemOffer].
class CategoryShopOffer {
  const CategoryShopOffer({
    required this.shopId,
    required this.itemId,
    required this.itemName,
    required this.itemUnit,
    required this.startingPriceTzs,
  });

  final String shopId;

  /// The specific item this price is for — added to the cart as a real,
  /// catalogued line rather than a synthetic key.
  final String itemId;
  final String itemName;
  final String itemUnit;
  final double startingPriceTzs;
}

/// Active shops carrying [categoryId], each with their cheapest item.
final categoryShopsProvider = FutureProvider.family<List<CategoryShopOffer>, String>((ref, categoryId) async {
  final data = await api.getCategoryShops(categoryId);
  final body = (data['data'] ?? data) as Map<String, dynamic>;
  final shops = (body['shops'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  return shops
      .map((j) => CategoryShopOffer(
            shopId: '${j['shop_id'] ?? ''}',
            itemId: '${j['item_id'] ?? ''}',
            itemName: j['item_name'] as String? ?? '',
            itemUnit: j['item_unit'] as String? ?? 'per piece',
            startingPriceTzs: parseDouble(j['starting_price_tzs']) ?? 0,
          ))
      .toList();
});

/// Active packages for one shop (by backend shop id).
final shopPackagesProvider = FutureProvider.family<List<ServicePackage>, String>((ref, shopId) async {
  final data = await api.getPackages(shopId);
  return data.map(packageFromJson).where((p) => p.active).toList();
});

/// The per-piece price list for one shop (by slug), built from the shop's
/// live vendor_items.
final shopDetailProvider = FutureProvider.family<List<MenuItem>, String>((ref, slug) async {
  final detail = await api.getShop(slug);
  final body = (detail['data'] ?? detail) as Map<String, dynamic>;
  final vendorItems = (body['vendor_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  return [
    for (final vi in vendorItems)
      if ((vi['is_available'] as bool? ?? true))
        MenuItem(
          key: '${vi['item_id'] ?? vi['item']?['id'] ?? ''}',
          name: vi['item']?['name'] as String? ?? '',
          unit: '${vi['item']?['unit'] ?? 'per piece'}',
          initial: (vi['item']?['name'] as String?)?.isNotEmpty == true
              ? (vi['item']['name'] as String)[0].toUpperCase()
              : '?',
          price: parseDouble(vi['price_tzs']) ?? 0,
        ),
  ];
});
