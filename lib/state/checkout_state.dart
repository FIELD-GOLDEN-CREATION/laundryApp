import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../utils/num_helper.dart';

class CheckoutState {
  const CheckoutState({
    this.payIndex = 0,
    this.promo = '',
    this.selectedCardId,
    this.selectedMobileProvider,
    this.mobileMoneyPhone,
    this.appliedPromoCode,
    this.promoError = '',
    this.discountAmount = 0,
    this.isValidatingPromo = false,
    this.deliveryFee = 0,
  });

  final int payIndex;
  final String promo;
  final String? selectedCardId;
  final String? selectedMobileProvider;
  final String? mobileMoneyPhone;
  final String? appliedPromoCode;
  final String promoError;
  final double discountAmount;
  final bool isValidatingPromo;
  final double deliveryFee;

  CheckoutState copyWith({
    int? payIndex,
    String? promo,
    String? selectedCardId,
    String? selectedMobileProvider,
    String? mobileMoneyPhone,
    String? appliedPromoCode,
    String? promoError,
    double? discountAmount,
    bool? isValidatingPromo,
    double? deliveryFee,
  }) =>
      CheckoutState(
        payIndex: payIndex ?? this.payIndex,
        promo: promo ?? this.promo,
        selectedCardId: selectedCardId ?? this.selectedCardId,
        selectedMobileProvider: selectedMobileProvider ?? this.selectedMobileProvider,
        mobileMoneyPhone: mobileMoneyPhone ?? this.mobileMoneyPhone,
        appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
        promoError: promoError ?? this.promoError,
        discountAmount: discountAmount ?? this.discountAmount,
        isValidatingPromo: isValidatingPromo ?? this.isValidatingPromo,
        deliveryFee: deliveryFee ?? this.deliveryFee,
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

  Future<void> applyPromo(double subtotal, String shopId) async {
    final code = state.promo.trim();
    if (code.isEmpty) {
      state = state.copyWith(promoError: 'Enter a promo code');
      return;
    }

    state = state.copyWith(isValidatingPromo: true, promoError: '');
    try {
      final data = await api.validatePromo(code, shopId, subtotal);
      final discount = parseDouble(data['discount']) ?? 0;
      state = state.copyWith(
        appliedPromoCode: code,
        promoError: '',
        discountAmount: discount,
        isValidatingPromo: false,
      );
    } on ValidationException catch (e) {
      state = state.copyWith(
        promoError: e.message,
        isValidatingPromo: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        promoError: e.message,
        isValidatingPromo: false,
      );
    }
  }

  void removePromo() {
    state = state.copyWith(
      appliedPromoCode: null,
      promo: '',
      promoError: '',
      discountAmount: 0,
    );
  }

  Future<void> loadDeliveryFee(String shopId, String address) async {
    try {
      final data = await api.getDeliveryFee(shopId, address);
      final fee = parseDouble(data['fee']) ?? 0;
      state = state.copyWith(deliveryFee: fee);
    } on ApiException {
      // Keep default
    }
  }
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);
