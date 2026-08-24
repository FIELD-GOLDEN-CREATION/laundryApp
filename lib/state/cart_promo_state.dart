import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/promo_mock_data.dart';
import '../models/promo_offer.dart';

class CartPromoState {
  const CartPromoState({
    this.promo = '',
    this.appliedPromoId,
    this.promoError = '',
    this.discountAmount = 0,
    this.appliedPromo,
  });

  final String promo;
  final String? appliedPromoId;
  final String promoError;
  final double discountAmount;
  final PromoOffer? appliedPromo;

  bool get hasPromo => appliedPromoId != null;

  CartPromoState copyWith({
    String? promo,
    String? appliedPromoId,
    String? promoError,
    double? discountAmount,
    PromoOffer? appliedPromo,
    bool clearPromo = false,
  }) => CartPromoState(
    promo: promo ?? this.promo,
    appliedPromoId: clearPromo ? null : (appliedPromoId ?? this.appliedPromoId),
    promoError: promoError ?? this.promoError,
    discountAmount: clearPromo ? 0 : (discountAmount ?? this.discountAmount),
    appliedPromo: clearPromo ? null : (appliedPromo ?? this.appliedPromo),
  );
}

class CartPromoNotifier extends Notifier<CartPromoState> {
  @override
  CartPromoState build() => const CartPromoState();

  void setPromo(String promo) => state = state.copyWith(promo: promo, promoError: '');

  void applyPromo(double subtotal) {
    final code = state.promo.trim();
    if (code.isEmpty) {
      state = state.copyWith(promoError: 'Enter a promo code');
      return;
    }

    final promo = findPromoByCode(code);
    if (promo == null) {
      state = state.copyWith(promoError: 'Invalid promo code');
      return;
    }

    if (promo.isExpired) {
      state = state.copyWith(promoError: 'This promo has expired');
      return;
    }

    if (!promo.isActive) {
      state = state.copyWith(promoError: 'This promo is no longer active');
      return;
    }

    if (promo.minSpend > 0 && subtotal < promo.minSpend) {
      state = state.copyWith(promoError: 'Minimum spend is TZS ${promo.minSpend.round()}');
      return;
    }

    if (promo.maxRedemptions != null && promo.currentRedemptions >= promo.maxRedemptions!) {
      state = state.copyWith(promoError: 'Redemption limit reached');
      return;
    }

    final discount = _calculateDiscount(promo, subtotal);
    state = state.copyWith(
      appliedPromoId: promo.id,
      appliedPromo: promo,
      promoError: '',
      discountAmount: discount,
    );
  }

  void removePromo() => state = state.copyWith(clearPromo: true);

  double _calculateDiscount(PromoOffer promo, double subtotal) {
    if (promo.isPercentage) {
      return subtotal * (promo.discountValue / 100);
    }
    return promo.discountValue;
  }
}

final cartPromoProvider = NotifierProvider<CartPromoNotifier, CartPromoState>(CartPromoNotifier.new);
