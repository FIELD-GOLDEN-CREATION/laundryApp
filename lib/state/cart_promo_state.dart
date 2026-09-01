import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/promo_offer.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';

class CartPromoState {
  const CartPromoState({
    this.promo = '',
    this.appliedPromoId,
    this.promoError = '',
    this.discountAmount = 0,
    this.appliedPromo,
    this.isValidating = false,
    this.pending = false,
  });

  final String promo;
  final String? appliedPromoId;
  final String promoError;
  final double discountAmount;
  final PromoOffer? appliedPromo;
  final bool isValidating;

  /// True when a delivery-scoped promo was accepted but the delivery fee
  /// isn't quoted yet — `discountAmount` is 0 until [CartPromoNotifier
  /// .refreshPromo] resolves it for real.
  final bool pending;

  bool get hasPromo => appliedPromoId != null;

  CartPromoState copyWith({
    String? promo,
    String? appliedPromoId,
    String? promoError,
    double? discountAmount,
    PromoOffer? appliedPromo,
    bool? isValidating,
    bool? pending,
    bool clearPromo = false,
  }) =>
      CartPromoState(
        promo: promo ?? this.promo,
        appliedPromoId: clearPromo ? null : (appliedPromoId ?? this.appliedPromoId),
        promoError: promoError ?? this.promoError,
        discountAmount: clearPromo ? 0 : (discountAmount ?? this.discountAmount),
        appliedPromo: clearPromo ? null : (appliedPromo ?? this.appliedPromo),
        isValidating: isValidating ?? this.isValidating,
        pending: clearPromo ? false : (pending ?? this.pending),
      );
}

class CartPromoNotifier extends Notifier<CartPromoState> {
  @override
  CartPromoState build() => const CartPromoState();

  void setPromo(String promo) => state = state.copyWith(promo: promo, promoError: '');

  Future<void> applyPromo(
    double subtotal,
    String shopId, {
    Map<int, int> cartItems = const {},
    String? packageId,
    bool isDelivery = false,
    int deliveryFeeTzs = 0,
  }) async {
    final code = state.promo.trim();
    if (code.isEmpty) {
      state = state.copyWith(promoError: 'Enter a promo code');
      return;
    }
    await _resolve(
      code,
      subtotal,
      shopId,
      cartItems: cartItems,
      packageId: packageId,
      isDelivery: isDelivery,
      deliveryFeeTzs: deliveryFeeTzs,
    );
  }

  /// Re-validates the code that's already applied, against fresh inputs —
  /// used once the delivery fee is quoted on the Schedule screen, so a
  /// `pending` delivery-scoped discount resolves to a real amount before
  /// the order is placed. A no-op if nothing is applied.
  Future<void> refreshPromo(
    double subtotal,
    String shopId, {
    Map<int, int> cartItems = const {},
    String? packageId,
    bool isDelivery = false,
    int deliveryFeeTzs = 0,
  }) async {
    final code = state.appliedPromoId;
    if (code == null) return;
    await _resolve(
      code,
      subtotal,
      shopId,
      cartItems: cartItems,
      packageId: packageId,
      isDelivery: isDelivery,
      deliveryFeeTzs: deliveryFeeTzs,
    );
  }

  Future<void> _resolve(
    String code,
    double subtotal,
    String shopId, {
    required Map<int, int> cartItems,
    required String? packageId,
    required bool isDelivery,
    required int deliveryFeeTzs,
  }) async {
    state = state.copyWith(isValidating: true, promoError: '');
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
      // `promo_id`/`discount_amount_tzs` — this used to read a top-level
      // `discount`/`promo` shape that the API never sent, so a promo could
      // never actually apply even when the code itself was valid.
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
      state = state.copyWith(
        appliedPromoId: code,
        appliedPromo: promo,
        promoError: '',
        discountAmount: discount,
        isValidating: false,
        pending: promoData['pending'] as bool? ?? false,
      );
    } on ValidationException catch (e) {
      state = state.copyWith(promoError: e.message, isValidating: false);
    } on ApiException catch (e) {
      state = state.copyWith(promoError: e.message, isValidating: false);
    }
  }

  void removePromo() => state = state.copyWith(clearPromo: true);

  /// Full reset — used when the basket switches to a different vendor, since
  /// a promo validated against one shop's id/subtotal has no bearing on the
  /// next (see `widgets/basket_shop_guard.dart`).
  void clear() => state = const CartPromoState();
}

final cartPromoProvider = NotifierProvider<CartPromoNotifier, CartPromoState>(CartPromoNotifier.new);
