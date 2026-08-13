import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_data.dart';
import '../../models/saved_card.dart';
import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../../state/checkout_state.dart';
import '../../state/orders_state.dart';
import '../../state/saved_cards_state.dart';
import '../../state/schedule_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/link_card_sheet.dart';
import '../../widgets/primary_cta_bar.dart';
import '../../widgets/radio_option_card.dart';
import '../../widgets/round_back_button.dart';

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
    final address = kAddresses[schedule.addrIndex];
    final day = kDays[schedule.dayIndex];
    final pickupSummary = '${day.dow} ${day.num}, ${kTimeSlots[schedule.slotIndex]}';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
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
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PICKUP',
                      style: AppText.sans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: AppColors.cream.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 6),
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
                child: Text('PAYMENT', style: AppText.eyebrow()),
              ),
              Column(
                children: [
                  RadioOptionCard(
                    label: 'Card',
                    sub: selectedCard != null ? selectedCard.label : 'Choose or link a saved card',
                    selected: checkout.payIndex == 0,
                    onTap: () => _openCardPicker(context, ref),
                  ),
                  const SizedBox(height: 10),
                  RadioOptionCard(
                    label: 'Mobile Money',
                    sub: checkout.selectedMobileProvider != null
                        ? '${checkout.selectedMobileProvider} · ${checkout.mobileMoneyPhone}'
                        : 'Choose a provider',
                    selected: checkout.payIndex == 1,
                    onTap: () => _openMobileMoneyPicker(context),
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

void _openCardPicker(BuildContext context, WidgetRef ref) {
  final notifier = ref.read(checkoutProvider.notifier);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Consumer(
        builder: (consumerContext, sheetRef, _) {
          final cards = sheetRef.watch(savedCardsProvider);
          final selectedId = sheetRef.watch(checkoutProvider.select((s) => s.selectedCardId));

          return Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                Text('Choose a card', style: AppText.serif(fontSize: 22)),
                const SizedBox(height: 14),
                if (cards.isEmpty)
                  Text(
                    'No saved cards yet.',
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                  )
                else
                  Column(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        RadioOptionCard(
                          label: cards[i].label,
                          sub: '${cards[i].holderName} · Expires ${cards[i].expiry}',
                          selected: selectedId == cards[i].id,
                          onTap: () {
                            notifier.selectCard(cards[i].id);
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                        if (i != cards.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        showLinkCardSheet(context, ref, onSaved: (card) => notifier.selectCard(card.id));
                      },
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: Text(
                          '+ Link a new card',
                          style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _openMobileMoneyPicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _MobileMoneySheet(),
  );
}

/// Digits-only Tanzanian mobile number: 10 digits with a leading 0
/// (e.g. 0754111222), or the same 9 digits without it.
final _kPhonePattern = RegExp(r'^(0\d{9}|\d{9})$');

class _MobileMoneySheet extends ConsumerStatefulWidget {
  const _MobileMoneySheet();

  @override
  ConsumerState<_MobileMoneySheet> createState() => _MobileMoneySheetState();
}

class _MobileMoneySheetState extends ConsumerState<_MobileMoneySheet> {
  late final _phoneCtrl = TextEditingController(text: ref.read(checkoutProvider).mobileMoneyPhone ?? '');
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _choose(String provider) {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (!_kPhonePattern.hasMatch(digits)) {
      setState(() => _error = 'Enter a valid mobile money number.');
      return;
    }
    ref.read(checkoutProvider.notifier).selectMobileProvider(provider, digits);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(checkoutProvider.select((s) => s.selectedMobileProvider));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            Text('Choose mobile money', style: AppText.serif(fontSize: 22)),
            const SizedBox(height: 3),
            Text(
              'The payment prompt is sent to this number',
              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Text('PHONE NUMBER', style: AppText.eyebrow()),
            const SizedBox(height: 7),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                decoration: InputDecoration.collapsed(
                  hintText: '0754 111 222',
                  hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger)),
            ],
            const SizedBox(height: 16),
            Column(
              children: [
                for (var i = 0; i < kMobileMoneyProviders.length; i++) ...[
                  RadioOptionCard(
                    label: kMobileMoneyProviders[i],
                    sub: 'Confirm the payment on your phone',
                    selected: selected == kMobileMoneyProviders[i],
                    onTap: () => _choose(kMobileMoneyProviders[i]),
                  ),
                  if (i != kMobileMoneyProviders.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
