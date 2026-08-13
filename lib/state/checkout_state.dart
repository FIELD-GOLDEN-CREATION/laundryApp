import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ports the source's `pay`, `promo` fields. Discount/total are pure
/// derived values (see mock_data.dart helpers) — Riverpod recomputes them
/// on every read automatically, so the source's `applyPromo:()=>forceUpdate()`
/// hack has nothing to port to.
///
/// `payIndex` selects the payment category (0 = Card, 1 = Mobile Money,
/// 2 = Cash on delivery); `selectedCardId`/`selectedMobileProvider`
/// (+ `mobileMoneyPhone`) carry the specific choice within the Card/Mobile
/// Money categories.
class CheckoutState {
  const CheckoutState({
    this.payIndex = 0,
    this.promo = '',
    this.selectedCardId,
    this.selectedMobileProvider,
    this.mobileMoneyPhone,
  });

  final int payIndex;
  final String promo;
  final String? selectedCardId;
  final String? selectedMobileProvider;
  final String? mobileMoneyPhone;

  CheckoutState copyWith({
    int? payIndex,
    String? promo,
    String? selectedCardId,
    String? selectedMobileProvider,
    String? mobileMoneyPhone,
  }) => CheckoutState(
    payIndex: payIndex ?? this.payIndex,
    promo: promo ?? this.promo,
    selectedCardId: selectedCardId ?? this.selectedCardId,
    selectedMobileProvider: selectedMobileProvider ?? this.selectedMobileProvider,
    mobileMoneyPhone: mobileMoneyPhone ?? this.mobileMoneyPhone,
  );
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutState();

  void pickPayment(int i) => state = state.copyWith(payIndex: i);
  void setPromo(String promo) => state = state.copyWith(promo: promo);
  void selectCard(String id) => state = state.copyWith(payIndex: 0, selectedCardId: id);

  void selectMobileProvider(String name, String phone) =>
      state = state.copyWith(payIndex: 1, selectedMobileProvider: name, mobileMoneyPhone: phone);
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

double discountFor(String promo) => promo.trim().isNotEmpty ? 10400.0 : 0.0;
