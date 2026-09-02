import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_item.dart';
import '../models/promo_offer.dart';
import '../models/service_package.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';
import 'cart_promo_state.dart';

/// One vendor's basket: qty, priced catalog, active package, selected
/// add-ons, delivery mode/fee and promo state, all bundled together so they
/// can never drift out of sync with each other for that vendor.
///
/// `shopId` (the backend's real numeric shop id) is both this basket's own
/// identity and the key `BasketsNotifier` stores it under — a package/item
/// added under one shopId can never be read back under another's, which is
/// what actually prevents cross-vendor basket mixing (previously "policed"
/// by a runtime confirm-before-switch guard that only fired on explicit add
/// actions and did nothing for mere browsing).
class VendorBasket {
  const VendorBasket({
    required this.shopId,
    this.shopName = '',
    this.shopSlug = '',
    this.qty = const {},
    this.catalog = const {},
    this.extraItems = const {},
    this.activePackage,
    this.selectedAddonIndices = const {},
    this.mode = 'delivery',
    this.deliveryFeeTzs = 0,
    this.quoting = false,
    this.promo = const CartPromoState(),
  });

  factory VendorBasket.empty(String shopId) => VendorBasket(shopId: shopId);

  final String shopId;
  final String shopName;
  final String shopSlug;

  /// Item/package cart key -> quantity, scoped to this vendor alone.
  final Map<String, int> qty;

  /// Every priced item this vendor's customer can order — per-piece menu
  /// plus package/addon extras. Merged by key rather than concatenated:
  /// `addServiceItem` deliberately writes each line into both maps (so a
  /// package/addon line survives whichever one a given screen checks), and
  /// concatenating would double-bill and double-render it.
  final Map<String, MenuItem> catalog;
  final Map<String, MenuItem> extraItems;

  final ServicePackage? activePackage;
  final Set<int> selectedAddonIndices;

  final String mode;
  final int deliveryFeeTzs;
  final bool quoting;

  final CartPromoState promo;

  List<MenuItem> get pricedItems => {...catalog, ...extraItems}.values.toList();
  bool get isDelivery => mode == 'delivery';
  bool get hasContent => qty.values.any((n) => n > 0);

  VendorBasket copyWith({
    String? shopName,
    String? shopSlug,
    Map<String, int>? qty,
    Map<String, MenuItem>? catalog,
    Map<String, MenuItem>? extraItems,
    ServicePackage? activePackage,
    bool clearActivePackage = false,
    Set<int>? selectedAddonIndices,
    String? mode,
    int? deliveryFeeTzs,
    bool? quoting,
    CartPromoState? promo,
  }) =>
      VendorBasket(
        shopId: shopId,
        shopName: shopName ?? this.shopName,
        shopSlug: shopSlug ?? this.shopSlug,
        qty: qty ?? this.qty,
        catalog: catalog ?? this.catalog,
        extraItems: extraItems ?? this.extraItems,
        activePackage: clearActivePackage ? null : (activePackage ?? this.activePackage),
        selectedAddonIndices: selectedAddonIndices ?? this.selectedAddonIndices,
        mode: mode ?? this.mode,
        deliveryFeeTzs: deliveryFeeTzs ?? this.deliveryFeeTzs,
        quoting: quoting ?? this.quoting,
        promo: promo ?? this.promo,
      );
}

/// All active per-vendor baskets, keyed by `Shop.slotId`. Absent entries
/// read as an empty basket for that shop (see `VendorBasket.empty`) —
/// nothing is created until the first write for that shopId.
class BasketsNotifier extends Notifier<Map<String, VendorBasket>> {
  @override
  Map<String, VendorBasket> build() => {};

  VendorBasket basketFor(String shopId) => state[shopId] ?? VendorBasket.empty(shopId);

  void _update(String shopId, VendorBasket Function(VendorBasket) update) {
    state = {...state, shopId: update(basketFor(shopId))};
  }

  void setShopCatalog(String shopId, {required String shopName, required String shopSlug, required List<MenuItem> items}) {
    _update(
      shopId,
      (b) => b.copyWith(
        shopName: shopName,
        shopSlug: shopSlug,
        catalog: {for (final item in items) item.key: item},
      ),
    );
  }

  void addServiceItem(String shopId, MenuItem item) {
    _update(
      shopId,
      (b) => b.copyWith(
        extraItems: {...b.extraItems, item.key: item},
        catalog: {...b.catalog, item.key: item},
      ),
    );
  }

  void setQty(String shopId, String key, int delta) {
    _update(shopId, (b) {
      final next = Map.of(b.qty);
      next[key] = ((next[key] ?? 0) + delta).clamp(0, 999);
      return b.copyWith(qty: next);
    });
  }

  /// Adds a package to [shopId]'s basket at qty 1, replacing whatever
  /// package was active there before.
  void addPackage(String shopId, ServicePackage pkg) {
    final prev = basketFor(shopId).activePackage;
    if (prev != null) {
      final prevKey = prev.cartKey(shopId);
      final prevQty = basketFor(shopId).qty[prevKey] ?? 0;
      if (prevQty > 0) setQty(shopId, prevKey, -prevQty);
    }
    final key = pkg.cartKey(shopId);
    addServiceItem(shopId, MenuItem(key: key, name: pkg.name, unit: pkg.cartSubtitle, initial: pkg.initial, price: pkg.priceTzs));
    setQty(shopId, key, 1);
    _update(shopId, (b) => b.copyWith(activePackage: pkg));
  }

  void incrementRate(String shopId) {
    final pkg = basketFor(shopId).activePackage;
    if (pkg == null) return;
    setQty(shopId, pkg.cartKey(shopId), 1);
  }

  /// Removes one of the active package. Reaching 0 removes it entirely,
  /// same as [removePackage].
  void decrementRate(String shopId) {
    final basket = basketFor(shopId);
    final pkg = basket.activePackage;
    if (pkg == null) return;
    final key = pkg.cartKey(shopId);
    final qty = basket.qty[key] ?? 0;
    setQty(shopId, key, -1);
    if (qty <= 1) _update(shopId, (b) => b.copyWith(clearActivePackage: true));
  }

  void removePackage(String shopId) {
    final basket = basketFor(shopId);
    final pkg = basket.activePackage;
    if (pkg != null) {
      final key = pkg.cartKey(shopId);
      final qty = basket.qty[key] ?? 0;
      if (qty > 0) setQty(shopId, key, -qty);
    }
    _update(shopId, (b) => b.copyWith(clearActivePackage: true));
  }

  void toggleAddon(String shopId, int index) {
    _update(shopId, (b) {
      final next = Set<int>.of(b.selectedAddonIndices);
      if (!next.remove(index)) next.add(index);
      return b.copyWith(selectedAddonIndices: next);
    });
  }

  void setMode(String shopId, String mode) {
    _update(shopId, (b) => b.copyWith(mode: mode, deliveryFeeTzs: mode == 'delivery' ? b.deliveryFeeTzs : 0));
  }

  void setQuoting(String shopId, bool quoting) => _update(shopId, (b) => b.copyWith(quoting: quoting));

  void finishQuote(String shopId, {required int fee}) => _update(shopId, (b) => b.copyWith(quoting: false, deliveryFeeTzs: fee));

  void setPromo(String shopId, String promo) {
    _update(shopId, (b) => b.copyWith(promo: b.promo.copyWith(promo: promo, promoError: '')));
  }

  Future<void> applyPromo(
    String shopId,
    double subtotal, {
    Map<int, int> cartItems = const {},
    String? packageId,
    bool isDelivery = false,
    int deliveryFeeTzs = 0,
  }) async {
    final code = basketFor(shopId).promo.promo.trim();
    if (code.isEmpty) {
      _update(shopId, (b) => b.copyWith(promo: b.promo.copyWith(promoError: 'Enter a promo code')));
      return;
    }
    await _resolvePromo(shopId, code, subtotal, cartItems: cartItems, packageId: packageId, isDelivery: isDelivery, deliveryFeeTzs: deliveryFeeTzs);
  }

  /// Re-validates the code that's already applied, against fresh inputs —
  /// used once the delivery fee is quoted on the Schedule screen, so a
  /// `pending` delivery-scoped discount resolves to a real amount before
  /// the order is placed. A no-op if nothing is applied for this shop.
  Future<void> refreshPromo(
    String shopId,
    double subtotal, {
    Map<int, int> cartItems = const {},
    String? packageId,
    bool isDelivery = false,
    int deliveryFeeTzs = 0,
  }) async {
    final code = basketFor(shopId).promo.appliedPromoId;
    if (code == null) return;
    await _resolvePromo(shopId, code, subtotal, cartItems: cartItems, packageId: packageId, isDelivery: isDelivery, deliveryFeeTzs: deliveryFeeTzs);
  }

  Future<void> _resolvePromo(
    String shopId,
    String code,
    double subtotal, {
    required Map<int, int> cartItems,
    required String? packageId,
    required bool isDelivery,
    required int deliveryFeeTzs,
  }) async {
    _update(shopId, (b) => b.copyWith(promo: b.promo.copyWith(isValidating: true, promoError: '')));
    try {
      final data = await api.validatePromo(
        code,
        shopId,
        subtotal,
        cartItems: cartItems,
        packageId: packageId,
        isDelivery: isDelivery,
        deliveryFeeTzs: deliveryFeeTzs,
      );
      // The backend nests its result under `data` and names fields
      // `promo_id`/`discount_amount_tzs`.
      final promoData = data['data'] as Map<String, dynamic>? ?? data;
      final discount = parseDouble(promoData['discount_amount_tzs']) ?? 0;
      final promo = PromoOffer(
        id: promoData['promo_id'] != null ? '${promoData['promo_id']}' : '',
        code: promoData['code'] as String? ?? code,
        title: promoData['title'] as String? ?? '',
        description: '',
        discountValue: parseDouble(promoData['discount_value']) ?? discount,
        isPercentage: promoData['is_percentage'] as bool? ?? false,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        imageUrl: '',
        vendorName: '',
        // Which entity this discount actually targets — the cart/schedule
        // total math needs this to subtract it from the right line
        // (subtotal vs. delivery) instead of always assuming subtotal.
        appliesTo: promoAppliesToFromJson(promoData['applies_to'] as String?),
      );
      _update(
        shopId,
        (b) => b.copyWith(
          promo: b.promo.copyWith(
            appliedPromoId: code,
            appliedPromo: promo,
            promoError: '',
            discountAmount: discount,
            isValidating: false,
            pending: promoData['pending'] as bool? ?? false,
          ),
        ),
      );
    } on ValidationException catch (e) {
      _update(shopId, (b) => b.copyWith(promo: b.promo.copyWith(promoError: e.message, isValidating: false)));
    } on ApiException catch (e) {
      _update(shopId, (b) => b.copyWith(promo: b.promo.copyWith(promoError: e.message, isValidating: false)));
    }
  }

  void removePromo(String shopId) => _update(shopId, (b) => b.copyWith(promo: b.promo.copyWith(clearPromo: true)));

  /// Drops [shopId]'s basket entirely — used once its order is placed.
  /// Removes only that one entry; every other vendor's in-progress basket
  /// is left untouched.
  void clearBasket(String shopId) {
    final next = {...state}..remove(shopId);
    state = next;
  }
}

final basketsProvider = NotifierProvider<BasketsNotifier, Map<String, VendorBasket>>(BasketsNotifier.new);
