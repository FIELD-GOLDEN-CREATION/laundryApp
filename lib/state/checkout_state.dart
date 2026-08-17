import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/promo_mock_data.dart';
import '../models/promo_offer.dart';

class CheckoutState {
  const CheckoutState({
    this.payIndex = 0,
    this.promo = '',
    this.selectedCardId,
    this.selectedMobileProvider,
    this.mobileMoneyPhone,
    this.appliedPromoId,
    this.promoError = '',
    this.discountAmount = 0,
  });

  final int payIndex;
  final String promo;
  final String? selectedCardId;
  final String? selectedMobileProvider;
  final String? mobileMoneyPhone;
  final String? appliedPromoId;
  final String promoError;
  final double discountAmount;

  CheckoutState copyWith({
    int? payIndex,
    String? promo,
    String? selectedCardId,
    String? selectedMobileProvider,
    String? mobileMoneyPhone,
    String? appliedPromoId,
    String? promoError,
    double? discountAmount,
  }) => CheckoutState(
    payIndex: payIndex ?? this.payIndex,
    promo: promo ?? this.promo,
    selectedCardId: selectedCardId ?? this.selectedCardId,
    selectedMobileProvider: selectedMobileProvider ?? this.selectedMobileProvider,
    mobileMoneyPhone: mobileMoneyPhone ?? this.mobileMoneyPhone,
    appliedPromoId: appliedPromoId ?? this.appliedPromoId,
    promoError: promoError ?? this.promoError,
    discountAmount: discountAmount ?? this.discountAmount,
  );
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  void pickPayment(int i) => state = state.copyWith(payIndex: i);
  void setPromo(String promo) => state = state.copyWith(promo: promo, promoError: '');
  void selectCard(String id) => state = state.copyWith(payIndex: 0, selectedCardId: id);

  void selectMobileProvider(String name, String phone) =>
      state = state.copyWith(payIndex: 1, selectedMobileProvider: name, mobileMoneyPhone: phone);

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
      state = state.copyWith(promoError: 'This promo has reached its redemption limit');
      return;
    }

    final discount = _calculateDiscount(promo, subtotal);
    state = state.copyWith(
      appliedPromoId: promo.id,
      promoError: '',
      discountAmount: discount,
    );
  }

  void removePromo() {
    state = state.copyWith(
      appliedPromoId: null,
      promo: '',
      promoError: '',
      discountAmount: 0,
    );
  }

  double _calculateDiscount(PromoOffer promo, double subtotal) {
    if (promo.isPercentage) {
      return subtotal * (promo.discountValue / 100);
    }
    return promo.discountValue;
  }
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

double discountFor(String promo) => promo.trim().isNotEmpty ? 10400.0 : 0.0;
