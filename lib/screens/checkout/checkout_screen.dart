import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../data/mock_data.dart';
import '../../models/address.dart';
import '../../models/mobile_money_provider.dart';
import '../../models/saved_card.dart';
import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../../state/checkout_state.dart';
import '../../state/orders_state.dart';
import '../../state/saved_cards_state.dart';
import '../../state/schedule_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/card_brand_tag.dart';
import '../../widgets/card_preview.dart';
import '../../widgets/announcement_banner.dart';
import '../../widgets/mobile_money_logo.dart';
import '../../widgets/payment_processing.dart';
import '../../widgets/primary_cta_bar.dart';
import '../../widgets/radio_option_card.dart';
import '../../widgets/remote_image.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/shake_widget.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider);
    final schedule = ref.watch(scheduleProvider);
    final checkout = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final savedCards = ref.watch(savedCardsProvider);
    final selectedCard = savedCards
        .cast<SavedCard?>()
        .firstWhere((c) => c?.id == checkout.selectedCardId, orElse: () => null);

    final subtotal = cartSubtotal(qty);
    final discount = discountFor(checkout.promo);
    final total = (subtotal - discount).clamp(0, double.infinity);
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
                  Text('Checkout', style: AppText.serif(fontSize: 24)),
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
                        Expanded(child: Text('PICKUP DETAILS', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: AppColors.cream.withValues(alpha: 0.68)))),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: AppColors.cream.withValues(alpha: 0.18)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${cartItemCount(qty)} items · Marina Fresh',
                          style: AppText.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cream.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          'Delivered Thu, 6 PM',
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
                    Text('PAYMENT METHOD', style: AppText.eyebrow()),
                    Row(children: [const Icon(Icons.lock_outline_rounded, size: 13, color: AppColors.teal), const SizedBox(width: 4), Text('Secure checkout', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal))]),
                  ],
                ),
              ),
              Column(
                children: [
                  RadioOptionCard(
                    label: 'Card',
                    sub: selectedCard != null ? selectedCard.label : 'Choose or link a saved card',
                    selected: checkout.payIndex == 0,
                    leading: const SizedBox(
                      width: 44,
                      height: 44,
                      child: RemoteImage(url: kCardPhotoUrl, fallback: 'Card', borderRadius: 10),
                    ),
                    onTap: () => _openCardPay(
                      context,
                      shop: 'Marina Fresh Laundry',
                      items: '${cartItemCount(qty)} items',
                      total: formatMoney(total.toDouble()),
                      pickup: pickupSummary,
                      address: address.line,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioOptionCard(
                    label: 'Mobile Money',
                    sub: checkout.selectedMobileProvider != null
                        ? '${checkout.selectedMobileProvider} · ${checkout.mobileMoneyPhone}'
                        : 'Choose a provider',
                    selected: checkout.payIndex == 1,
                    leading: checkout.selectedMobileProvider != null
                        ? MobileMoneyLogo(provider: mobileProviderByName(checkout.selectedMobileProvider!)!)
                        : null,
                    onTap: () => _openMobileMoneyPicker(
                      context,
                      shop: 'Marina Fresh Laundry',
                      items: '${cartItemCount(qty)} items',
                      total: formatMoney(total.toDouble()),
                      pickup: pickupSummary,
                      address: address.line,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioOptionCard(
                    label: 'Cash on delivery',
                    sub: 'Pay the driver',
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
                        color: Colors.white,
                        border: Border.all(color: AppColors.amber, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        onChanged: checkoutNotifier.setPromo,
                        style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Promo code',
                          hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: AppColors.amberLight,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {},
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        child: Text(
                          'Apply',
                          style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.amber),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.creamDark),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _Line(label: 'Subtotal', value: formatMoney(subtotal)),
                    const SizedBox(height: 9),
                    _Line(
                      label: 'Discount',
                      value: discount > 0 ? '−${formatMoney(discount)}' : '—',
                      valueColor: AppColors.amber,
                    ),
                    const SizedBox(height: 9),
                    const _Line(label: 'Pickup & delivery', value: 'Free', valueColor: AppColors.teal),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Divider(height: 1, color: AppColors.creamDark),
                    ),
                    _Line(
                      label: 'Total',
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
        label: 'Place order',
        hint: formatMoney(total.toDouble()),
        onPressed: () {
          if (gateGuest(ref, context, 'Log in to place your order — guests can browse everything else.')) return;
          final order = ref
              .read(ordersProvider.notifier)
              .placeOrder(
                shop: 'Marina Fresh Laundry',
                items: '${cartItemCount(qty)} items',
                total: formatMoney(total.toDouble()),
                paymentMethod: _paymentLabel(checkout, selectedCard),
                pickup: pickupSummary,
                address: address.line,
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
String _paymentLabel(CheckoutState checkout, SavedCard? selectedCard) {
  switch (checkout.payIndex) {
    case 0:
      return selectedCard != null ? 'Card · ${selectedCard.label}' : 'Card';
    case 1:
      final p = checkout.selectedMobileProvider;
      return p != null ? 'Mobile money · $p' : 'Mobile money';
    default:
      return 'Cash on delivery';
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
  required String shop,
  required String items,
  required String total,
  required String pickup,
  required String address,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CardSheet(shop: shop, items: items, total: total, pickup: pickup, address: address),
  );
}

String _cardDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

class _CardSheet extends ConsumerStatefulWidget {
  const _CardSheet({required this.shop, required this.items, required this.total, required this.pickup, required this.address});

  final String shop;
  final String items;
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

    final order = ref.read(ordersProvider.notifier).placeOrder(
      shop: widget.shop,
      items: widget.items,
      total: widget.total,
      paymentMethod: paymentMethod,
      pickup: widget.pickup,
      address: widget.address,
    );
    navigator.pop();
    router.go('/order-confirmation', extra: order.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
            color: Colors.white,
            border: Border.all(color: AppColors.creamDark),
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
                  style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
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
  required String shop,
  required String items,
  required String total,
  required String pickup,
  required String address,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _MobileMoneySheet(shop: shop, items: items, total: total, pickup: pickup, address: address),
  );
}

enum _PayPhase { input, processing, approved }

class _MobileMoneySheet extends ConsumerStatefulWidget {
  const _MobileMoneySheet({required this.shop, required this.items, required this.total, required this.pickup, required this.address});

  final String shop;
  final String items;
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

    final order = ref.read(ordersProvider.notifier).placeOrder(
      shop: widget.shop,
      items: widget.items,
      total: widget.total,
      paymentMethod: 'Mobile money · ${provider.name}',
      pickup: widget.pickup,
      address: widget.address,
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
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              color: Colors.white,
              border: Border.all(color: AppColors.creamDark),
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
                    style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w700),
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
