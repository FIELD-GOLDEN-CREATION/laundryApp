import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../data/mock_data.dart';
import '../../../models/address.dart';
import '../../../models/mobile_money_provider.dart';
import '../../../models/saved_card.dart';
import '../../../state/auth_state.dart';
import '../../../state/cart_state.dart';
import '../../../state/checkout_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../state/fulfillment_state.dart';
import '../../../state/place_order_helper.dart';
import '../../../state/saved_cards_state.dart';
import '../../../state/schedule_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/card_brand_tag.dart';
import '../../../widgets/card_preview.dart';
import '../../../widgets/announcement_banner.dart';
import '../../../widgets/mobile_money_logo.dart';
import '../../../widgets/payment_processing.dart';
import '../../../widgets/primary_cta_bar.dart';
import '../../../widgets/radio_option_card.dart';
import '../../../widgets/remote_image.dart';
import '../../../widgets/round_back_button.dart';
import '../../../widgets/shake_widget.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider);
    final schedule = ref.watch(scheduleProvider);
    final checkout = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final savedCards = ref.watch(savedCardsProvider);
    final fulfillment = ref.watch(fulfillmentProvider);
    final language = ref.watch(clientPreferencesProvider).language;
    final extra = fulfillment.extraItems.values.toList();
    final selectedCard = savedCards
        .cast<SavedCard?>()
        .firstWhere((c) => c?.id == checkout.selectedCardId, orElse: () => null);

    final subtotal = cartSubtotal(qty, extra);
    final discount = checkout.discountAmount;
    final deliveryFee = fulfillment.isDelivery ? fulfillment.deliveryFeeTzs : 0;
    final total = (subtotal - discount).clamp(0, double.infinity) + deliveryFee;
    final itemsCount = cartItemCount(qty, extra);
    final address = schedule.isCurrentLocation
        ? Address(label: 'Current location', line: schedule.currentLocation.isEmpty ? 'Current location' : schedule.currentLocation)
        : kAddresses[schedule.addrIndex];
    final day = kDays[schedule.dayIndex];
    final pickupSummary = '${day.dow} ${day.num}, ${kTimeSlots[schedule.slotIndex]}';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AnnouncementBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RoundBackButton(onPressed: () => context.pop()),
                  const SizedBox(width: 12),
                   Text(clientLabel('Checkout', 'Kulipa', language), style: AppText.serif(fontSize: 24, color: AppColors.clientText(context))),
                ],
              ),
              const SizedBox(height: 16),
              const _CheckoutProgress(),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.teal, Color(0xFF124944)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.2), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.local_laundry_service_rounded, size: 18, color: AppColors.cream)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(fulfillment.isDelivery ? clientLabel('PICKUP DETAILS', 'MZIGO UTAKACHUKULIWA', language) : clientLabel('DROP-OFF DETAILS', 'UNIPEO KELEE DUKANI', language), style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: AppColors.cream.withValues(alpha: 0.68)))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(99)), child: Text('READY', style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.mint, letterSpacing: 0.5))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pickupSummary,
                      style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cream),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.line,
                      style: AppText.sans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cream.withValues(alpha: 0.72),
                      ),
                    ),
                    if (fulfillment.isDelivery && fulfillment.driver.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.person_pin_circle_outlined, size: 15, color: AppColors.mint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${clientLabel('Driver', 'Dereva', language)}: ${fulfillment.driver} · ${formatMoney(deliveryFee.toDouble())}',
                            style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.cream.withValues(alpha: 0.8)),
                          ),
                        ),
                      ]),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: AppColors.cream.withValues(alpha: 0.18)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$itemsCount ${clientLabel('items', 'vitu', language)} · ${fulfillment.shop}',
                          style: AppText.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cream.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          fulfillment.isDelivery
                              ? clientLabel('Delivered by driver', 'Unapokea kwa dereva', language)
                              : clientLabel('You drop off at shop', 'Unapeleka dukani', language),
                          style: AppText.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cream.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(clientLabel('PAYMENT METHOD', 'NJIA YA MALIPO', language), style: AppText.eyebrow()),
                    Row(children: [const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.teal), const SizedBox(width: 4), Text(clientLabel('Secure checkout', 'Malipo salama', language), style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal))]),
                  ],
                ),
              ),
              Column(
                children: [
                  RadioOptionCard(
                    label: clientLabel('Card', 'Kadi', language),
                    sub: selectedCard != null ? selectedCard.label : clientLabel('Choose or link a saved card', 'Chagua au ongeza kadi', language),
                    selected: checkout.payIndex == 0,
                    leading: const SizedBox(
                      width: 44,
                      height: 44,
                      child: RemoteImage(url: kCardPhotoUrl, fallback: 'Card', borderRadius: 10),
                    ),
                    onTap: () => _openCardPay(
                      context,
                      total: formatMoney(total.toDouble()),
                      pickup: pickupSummary,
                      address: address.line,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioOptionCard(
                    label: clientLabel('Mobile Money', 'Lipa kwa simu', language),
                    sub: checkout.selectedMobileProvider != null
                        ? '${checkout.selectedMobileProvider} · ${checkout.mobileMoneyPhone}'
                        : clientLabel('Choose a provider', 'Chagua mtoa huduma', language),
                    selected: checkout.payIndex == 1,
                    leading: checkout.selectedMobileProvider != null
                        ? MobileMoneyLogo(provider: mobileProviderByName(checkout.selectedMobileProvider!)!)
                        : null,
                    onTap: () => _openMobileMoneyPicker(
                      context,
                      total: formatMoney(total.toDouble()),
                      pickup: pickupSummary,
                      address: address.line,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioOptionCard(
                    label: fulfillment.isDelivery ? clientLabel('Cash on delivery', 'Lipa kwa cash', language) : clientLabel('Cash at shop', 'Lipa dukani', language),
                    sub: fulfillment.isDelivery ? clientLabel('Pay the driver', 'Mlipe dereva', language) : clientLabel('Pay at the shop counter', 'Lipa kaunta ya duka', language),
                    selected: checkout.payIndex == 2,
                    onTap: () => checkoutNotifier.pickPayment(2),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                         color: AppColors.clientSurface(context),
                         border: Border.all(
                           color: checkout.appliedPromoId != null
                               ? AppColors.teal
                               : checkout.promoError.isNotEmpty
                                   ? AppColors.danger
                                   : AppColors.amber,
                         ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        onChanged: checkoutNotifier.setPromo,
                        enabled: checkout.appliedPromoId == null,
                        style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                        decoration: InputDecoration.collapsed(
                          hintText: checkout.appliedPromoId != null ? 'Promo applied!' : 'Promo code',
                          hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: checkout.appliedPromoId != null ? AppColors.teal : AppColors.muted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: checkout.appliedPromoId != null ? AppColors.dangerLight : AppColors.amberLight,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: checkout.appliedPromoId != null
                          ? () => checkoutNotifier.removePromo()
                          : () => checkoutNotifier.applyPromo(subtotal.toDouble()),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        child: Text(
                          checkout.appliedPromoId != null ? 'Remove' : 'Apply',
                          style: AppText.sans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: checkout.appliedPromoId != null ? AppColors.danger : AppColors.amber,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (checkout.promoError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  checkout.promoError,
                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                   color: AppColors.clientSurface(context),
                   border: Border.all(color: AppColors.clientBorder(context)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _Line(label: clientLabel('Subtotal', 'Jumla ndogo', language), value: formatMoney(subtotal)),
                    const SizedBox(height: 9),
                    _Line(
                      label: clientLabel('Discount', 'Punguzo', language),
                      value: discount > 0 ? '−${formatMoney(discount)}' : '—',
                      valueColor: AppColors.amber,
                    ),
                    const SizedBox(height: 9),
                    if (fulfillment.isDelivery)
                      _Line(
                        label: clientLabel('Pickup & delivery', 'Kuchukua na usafirishaji', language),
                        value: deliveryFee > 0 ? formatMoney(deliveryFee.toDouble()) : '—',
                        valueColor: AppColors.teal,
                      )
                    else
                      _Line(label: clientLabel('Self drop-off', 'Unapeleka mwenyewe', language), value: clientLabel('Free', 'Bure', language), valueColor: AppColors.teal),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Divider(height: 1, color: AppColors.clientBorder(context)),
                    ),
                    _Line(
                      label: clientLabel('Total', 'Jumla', language),
                      value: formatMoney(total.toDouble()),
                      bold: true,
                      valueColor: AppColors.teal,
                    ),
                  ],
                ),
              ),
            ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PrimaryCtaBar(
        label: clientLabel('Place order', 'Weka oda', language),
        hint: formatMoney(total.toDouble()),
        onPressed: () {
          if (gateGuest(ref, context, 'Log in to place your order — guests can browse everything else.')) return;
          final order = placeCurrentOrder(
            ref,
            paymentMethod: _paymentLabel(checkout, selectedCard, fulfillment.isDelivery),
            pickup: pickupSummary,
            address: address.line,
            total: formatMoney(total.toDouble()),
          );
          // Full location replace (not push) so the back gesture from the
          // confirmation screen can't land back in a placed order's
          // checkout.
          context.go('/order-confirmation', extra: order.id);
        },
      ),
    );
  }
}

class _CheckoutProgress extends StatelessWidget {
  const _CheckoutProgress();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProgressStep(number: '1', label: 'Schedule', active: false),
        Expanded(child: Container(height: 2, color: AppColors.teal)),
        _ProgressStep(number: '2', label: 'Payment', active: true),
        Expanded(child: Container(height: 2, color: AppColors.creamDark)),
        _ProgressStep(number: '3', label: 'Confirm', active: false),
      ],
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.number, required this.label, required this.active});

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: active ? AppColors.teal : AppColors.creamDark, shape: BoxShape.circle), child: Text(number, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: active ? AppColors.cream : AppColors.muted))),
        const SizedBox(height: 4),
        Text(label, style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: active ? AppColors.teal : AppColors.muted)),
      ],
    );
  }
}

/// The human-readable payment line shown on the order confirmation, derived
/// from the chosen payment category and any selection within it.
String _paymentLabel(CheckoutState checkout, SavedCard? selectedCard, [bool isDelivery = true]) {
  switch (checkout.payIndex) {
    case 0:
      return selectedCard != null ? 'Card · ${selectedCard.label}' : 'Card';
    case 1:
      final p = checkout.selectedMobileProvider;
      return p != null ? 'Mobile money · $p' : 'Mobile money';
    default:
      return isDelivery ? 'Cash on delivery' : 'Cash at shop';
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.bold = false, this.valueColor = AppColors.slate});

  final String label;
  final String value;
  final bool bold;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppText.sans(
            fontSize: bold ? 17 : 13.5,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: bold ? AppColors.slate : AppColors.muted,
          ),
        ),
        Text(
          value,
          style: AppText.sans(
            fontSize: bold ? 17 : 13.5,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

Widget _sheetHandle() => Center(
  child: Container(
    width: 44,
    height: 5,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: const Color(0xFFDED8CA), borderRadius: BorderRadius.circular(99)),
  ),
);

void _openCardPay(
  BuildContext context, {
  required String total,
  required String pickup,
  required String address,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CardSheet(total: total, pickup: pickup, address: address),
  );
}

String _cardDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

class _CardSheet extends ConsumerStatefulWidget {
  const _CardSheet({required this.total, required this.pickup, required this.address});

  final String total;
  final String pickup;
  final String address;

  @override
  ConsumerState<_CardSheet> createState() => _CardSheetState();
}

class _CardSheetState extends ConsumerState<_CardSheet> {
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  CardBrand _brand = CardBrand.bank;
  String? _selectedSavedCardId;
  _PayPhase _phase = _PayPhase.input;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  bool get _newCardValid {
    final digits = _cardDigits(_numberCtrl.text);
    return _nameCtrl.text.trim().isNotEmpty &&
        digits.length >= 12 &&
        digits.length <= 19 &&
        RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(_expiryCtrl.text.trim()) &&
        _cvvCtrl.text.trim().length >= 3 &&
        _cvvCtrl.text.trim().length <= 4;
  }

  bool get _valid => _selectedSavedCardId != null || _newCardValid;

  void _onNumberChanged(String v) {
    setState(() {
      _brand = detectCardBrand(_cardDigits(v));
      _selectedSavedCardId = null;
    });
  }

  void _selectSaved(String id) {
    setState(() => _selectedSavedCardId = id);
  }

  Future<void> _pay() async {
    if (!_valid) return;
    if (gateGuest(ref, context, 'Log in to pay with card.')) return;

    final savedId = _selectedSavedCardId;
    String paymentMethod;
    if (savedId != null) {
      ref.read(checkoutProvider.notifier).selectCard(savedId);
      final saved = ref.read(savedCardsProvider).cast<SavedCard?>().firstWhere((c) => c?.id == savedId, orElse: () => null);
      paymentMethod = 'Card · ${saved?.label ?? 'Card'}';
    } else {
      final digits = _cardDigits(_numberCtrl.text);
      final card = SavedCard(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        holderName: _nameCtrl.text.trim(),
        last4: digits.substring(digits.length - 4),
        expiry: _expiryCtrl.text.trim(),
        brand: detectCardBrand(digits),
      );
      ref.read(savedCardsProvider.notifier).add(card);
      ref.read(checkoutProvider.notifier).selectCard(card.id);
      paymentMethod = 'Card · ${brandLabel(card.brand)} •••• ${card.last4}';
    }

    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);

    setState(() => _phase = _PayPhase.processing);
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    setState(() => _phase = _PayPhase.approved);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final order = placeCurrentOrder(
      ref,
      paymentMethod: paymentMethod,
      pickup: widget.pickup,
      address: widget.address,
      total: widget.total,
    );
    navigator.pop();
    router.go('/order-confirmation', extra: order.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.clientSurfaceRaised(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: switch (_phase) {
              _PayPhase.input => _buildInput(),
              _PayPhase.processing => _buildProcessing(),
              _PayPhase.approved => _buildApproved(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    final savedCards = ref.watch(savedCardsProvider);
    final selected = savedCards.cast<SavedCard?>().firstWhere((c) => c?.id == _selectedSavedCardId, orElse: () => null);
    final brand = selected?.brand ?? _brand;
    final number = selected != null ? '•••• ${selected.last4}' : _numberCtrl.text;
    final name = selected?.holderName ?? _nameCtrl.text;
    final expiry = selected?.expiry ?? _expiryCtrl.text;

    return Column(
      key: const ValueKey('card-input'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetHandle(),
        Text('Pay with card', style: AppText.serif(fontSize: 22)),
        const SizedBox(height: 14),
        CardPreview(brand: brand, number: number, name: name, expiry: expiry),
        if (savedCards.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('SAVED CARDS', style: AppText.eyebrow()),
          const SizedBox(height: 8),
          for (var i = 0; i < savedCards.length; i++) ...[
            RadioOptionCard(
              label: savedCards[i].label,
              sub: '${savedCards[i].holderName} · Expires ${savedCards[i].expiry}',
              selected: _selectedSavedCardId == savedCards[i].id,
              leading: CardBrandTag(brand: savedCards[i].brand),
              onTap: () => _selectSaved(savedCards[i].id),
            ),
            if (i != savedCards.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          Text('OR ENTER A NEW CARD', style: AppText.eyebrow()),
        ],
        const SizedBox(height: 10),
        _CardField(
          label: 'Card number',
          hint: '4242 4242 4242 4242',
          controller: _numberCtrl,
          keyboardType: TextInputType.number,
          onChanged: _onNumberChanged,
          trailing: _numberCtrl.text.trim().isEmpty ? null : CardBrandTag(brand: _brand),
        ),
        const SizedBox(height: 10),
        _CardField(label: 'Name on card', hint: 'Amara Reed', controller: _nameCtrl),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _CardField(label: 'Expiry', hint: 'MM/YY', controller: _expiryCtrl, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CardField(label: 'CVV', hint: '123', controller: _cvvCtrl, obscure: true, keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Material(
          color: _valid ? AppColors.teal : AppColors.creamDark,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _valid ? _pay : null,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: Text(
                _valid ? 'Pay ${widget.total}' : 'Enter card details to pay',
                style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: _valid ? AppColors.cream : AppColors.muted),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing() {
    return Column(
      key: const ValueKey('card-processing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHandle(),
        const SizedBox(height: 16),
        PaymentProcessing(
          title: 'Processing payment…',
          subtitle: 'Approving ${widget.total} with your card',
          center: const Icon(Icons.credit_card, color: AppColors.cream, size: 30),
        ),
      ],
    );
  }

  Widget _buildApproved() {
    return Column(
      key: const ValueKey('card-approved'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHandle(),
        const SizedBox(height: 20),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const AppIcon(AppIcons.checkCircle, size: 46),
          ),
        ),
        const SizedBox(height: 22),
        Text('Payment approved', style: AppText.serif(fontSize: 21), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Confirming your order…',
          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({
    required this.label,
    required this.hint,
    required this.controller,
    this.trailing,
    this.onChanged,
    this.obscure = false,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.eyebrow()),
        const SizedBox(height: 7),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.clientSurface(context),
            border: Border.all(color: AppColors.clientBorder(context)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.clientText(context)),
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ],
    );
  }
}

void _openMobileMoneyPicker(
  BuildContext context, {
  required String total,
  required String pickup,
  required String address,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _MobileMoneySheet(total: total, pickup: pickup, address: address),
  );
}

enum _PayPhase { input, processing, approved }

class _MobileMoneySheet extends ConsumerStatefulWidget {
  const _MobileMoneySheet({required this.total, required this.pickup, required this.address});

  final String total;
  final String pickup;
  final String address;

  @override
  ConsumerState<_MobileMoneySheet> createState() => _MobileMoneySheetState();
}

class _MobileMoneySheetState extends ConsumerState<_MobileMoneySheet> {
  late final _phoneCtrl = TextEditingController(text: ref.read(checkoutProvider).mobileMoneyPhone ?? '');
  _PayPhase _phase = _PayPhase.input;
  int _shakeTrigger = 0;

  String get _digits => _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
  bool get _valid => _digits.length == 10 && detectMobileProvider(_digits) != null;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// Keeps the number at exactly 10 digits; an 11th keystroke is rejected
  /// with a shake instead of being silently dropped.
  void _onPhoneChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      _phoneCtrl.value = TextEditingValue(
        text: digits.substring(0, 10),
        selection: const TextSelection.collapsed(offset: 10),
      );
      setState(() => _shakeTrigger++);
      return;
    }
    setState(() {});
  }

  Future<void> _pay() async {
    final provider = detectMobileProvider(_digits);
    if (!_valid || provider == null) return;
    if (gateGuest(ref, context, 'Log in to pay with mobile money.')) return;

    ref.read(checkoutProvider.notifier).selectMobileProvider(provider.name, _digits);

    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);

    setState(() => _phase = _PayPhase.processing);
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    setState(() => _phase = _PayPhase.approved);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

final order = placeCurrentOrder(
      ref,
      paymentMethod: 'Mobile money · ${provider.name}',
      pickup: widget.pickup,
      address: widget.address,
      total: widget.total,
    );
    navigator.pop();
    router.go('/order-confirmation', extra: order.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        decoration: BoxDecoration(
          color: AppColors.clientSurfaceRaised(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: switch (_phase) {
            _PayPhase.input => _buildInput(),
            _PayPhase.processing => _buildProcessing(),
            _PayPhase.approved => _buildApproved(),
          },
        ),
      ),
    );
  }

  Widget _buildInput() {
    final provider = detectMobileProvider(_digits);
    return Column(
      key: const ValueKey('input'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetHandle(),
        Text('Pay with mobile money', style: AppText.serif(fontSize: 22)),
        const SizedBox(height: 3),
        Text(
          "We'll send a payment prompt to this number",
          style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        Text('PHONE NUMBER', style: AppText.eyebrow()),
        const SizedBox(height: 7),
        ShakeWidget(
          trigger: _shakeTrigger,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.clientSurface(context),
              border: Border.all(color: AppColors.clientBorder(context)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const AppIcon(AppIcons.phone, size: 16, color: AppColors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    onChanged: _onPhoneChanged,
                    style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.clientText(context)),
                    decoration: InputDecoration.collapsed(
                      hintText: '0754 111 222',
                      hintStyle: AppText.sans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ),
                ),
                if (provider != null) ...[
                  const SizedBox(width: 8),
                  MobileMoneyLogo(provider: provider, size: 32),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _DetectedProviderCard(provider: provider),
        const SizedBox(height: 20),
        Material(
          color: _valid ? AppColors.teal : AppColors.creamDark,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: _valid ? _pay : null,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: Text(
                _valid ? 'Pay ${widget.total}' : 'Enter number to pay',
                style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: _valid ? AppColors.cream : AppColors.muted),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing() {
    final selected = ref.read(checkoutProvider).selectedMobileProvider;
    final provider = detectMobileProvider(_digits) ?? mobileProviderByName(selected ?? '');
    return Column(
      key: const ValueKey('processing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHandle(),
        const SizedBox(height: 16),
        PaymentProcessing(
          title: 'Processing payment…',
          subtitle: provider == null ? 'Approving your payment' : 'Approving ${widget.total} with ${provider.name}',
          center: provider == null ? null : MobileMoneyLogo(provider: provider, size: 60),
        ),
      ],
    );
  }

  Widget _buildApproved() {
    return Column(
      key: const ValueKey('approved'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _sheetHandle(),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const AppIcon(AppIcons.checkCircle, size: 46),
          ),
        ),
        const SizedBox(height: 22),
        Text('Payment approved', style: AppText.serif(fontSize: 21), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Confirming your order…',
          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DetectedProviderCard extends StatelessWidget {
  const _DetectedProviderCard({required this.provider});

  final MobileMoneyProvider? provider;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: provider == null
          ? Text(
              "Enter your number — we'll detect your provider automatically",
              style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
            )
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  MobileMoneyLogo(provider: provider!, size: 34),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(provider!.name, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 1),
                        Text(
                          'Detected from your number',
                          style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const AppIcon(AppIcons.checkCircle, size: 18),
                ],
              ),
            ),
    );
  }
}
