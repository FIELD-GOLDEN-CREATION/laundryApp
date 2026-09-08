import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/promo_offer.dart';

/// Set when the customer explicitly claims a promo (taps "Copy Code" on a
/// home-screen offer card) and read once by the cart screen to prefill its
/// promo field. Consuming code must clear it back to null after reading —
/// this is a one-shot signal, not persistent state, and deliberately never
/// derived from the OS clipboard, which can hold unrelated text (e.g. a
/// phone number copied for some other reason) that happens to also look
/// like a code.
final claimedPromoCodeProvider = StateProvider<String?>((ref) => null);

/// One vendor basket's promo-code state. Nested inside `VendorBasket`
/// (see `vendor_basket.dart`) — the resolution logic that used to live on a
/// standalone `CartPromoNotifier` now lives on `BasketsNotifier`, keyed by
/// shop, so a promo validated against one vendor's subtotal/id can never
/// leak onto another vendor's basket.
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
  /// isn't quoted yet — `discountAmount` is 0 until `BasketsNotifier
  /// .refreshPromo` resolves it for real.
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
