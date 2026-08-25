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

  Future<void> applyPromo(double subtotal, String shopId) async {
    final code = state.promo.trim();
    if (code.isEmpty) {
      state = state.copyWith(promoError: 'Enter a promo code');
      return;
    }

    state = state.copyWith(isValidating: true, promoError: '');
    try {
      final data = await api.validatePromo(code, shopId, subtotal);
      final discount = parseDouble(data['discount']) ?? 0;
      final promoData = data['promo'] as Map<String, dynamic>?;
      final promo = promoData != null
          ? PromoOffer(
              id: promoData['id'] as String? ?? '',
              code: promoData['code'] as String? ?? code,
              title: promoData['title'] as String? ?? '',
              description: promoData['description'] as String? ?? '',
              discountValue: parseDouble(promoData['discount_value']) ?? discount,
              isPercentage: promoData['is_percentage'] as bool? ?? false,
              expiresAt: promoData['expires_at'] != null
                  ? DateTime.tryParse(promoData['expires_at'] as String) ?? DateTime.now().add(const Duration(days: 7))
                  : DateTime.now().add(const Duration(days: 7)),
              imageUrl: promoData['image_url'] as String? ?? '',
              vendorName: promoData['vendor_name'] as String? ?? '',
              vendorId: promoData['vendor_id'] as String?,
            )
          : null;
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
