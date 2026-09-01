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
  });

  final String promo;
  final String? appliedPromoId;
  final String promoError;
  final double discountAmount;
  final PromoOffer? appliedPromo;
  final bool isValidating;

  bool get hasPromo => appliedPromoId != null;

  CartPromoState copyWith({
    String? promo,
    String? appliedPromoId,
    String? promoError,
    double? discountAmount,
    PromoOffer? appliedPromo,
    bool? isValidating,
    bool clearPromo = false,
  }) =>
      CartPromoState(
        promo: promo ?? this.promo,
        appliedPromoId: clearPromo ? null : (appliedPromoId ?? this.appliedPromoId),
        promoError: promoError ?? this.promoError,
        discountAmount: clearPromo ? 0 : (discountAmount ?? this.discountAmount),
        appliedPromo: clearPromo ? null : (appliedPromo ?? this.appliedPromo),
        isValidating: isValidating ?? this.isValidating,
      );
}

class CartPromoNotifier extends Notifier<CartPromoState> {
  @override
  CartPromoState build() => const CartPromoState();

  void setPromo(String promo) => state = state.copyWith(promo: promo, promoError: '');

  Future<void> applyPromo(double subtotal, String shopId, {Map<int, int> cartItems = const {}}) async {
    final code = state.promo.trim();
    if (code.isEmpty) {
      state = state.copyWith(promoError: 'Enter a promo code');
      return;
    }

    state = state.copyWith(isValidating: true, promoError: '');
    try {
      final data = await api.validatePromo(code, shopId, subtotal, cartItems: cartItems);
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
      );
      state = state.copyWith(
        appliedPromoId: code,
        appliedPromo: promo,
        promoError: '',
        discountAmount: discount,
        isValidating: false,
      );
    } on ValidationException catch (e) {
      state = state.copyWith(promoError: e.message, isValidating: false);
    } on ApiException catch (e) {
      state = state.copyWith(promoError: e.message, isValidating: false);
    }
  }

  void removePromo() => state = state.copyWith(clearPromo: true);
}

final cartPromoProvider = NotifierProvider<CartPromoNotifier, CartPromoState>(CartPromoNotifier.new);
