import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../models/notification_item.dart';
import '../models/vendor_order.dart';
import '../models/vendor_order_decision.dart';
import '../models/vendor_payment_method.dart';
import '../state/notifications_state.dart';
import '../state/vendor_orders_state.dart';
import '../state/vendor_payment_methods_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../utils/currency.dart';
import 'mobile_money_logo.dart';
import 'vendor_pickup_map_card.dart';

/// Entry point for the "Accept order" flow: a confirmation dialog, then (if
/// confirmed) the details sheet where the vendor sets a delivery fee and
/// picks which saved payment methods to offer the client.
void showVendorAcceptFlow(BuildContext context, WidgetRef ref, VendorOrder order) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accept this order?', style: AppText.serif(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              "You're about to accept ${order.customer}'s order (${order.id}). "
              "Next you'll set a delivery fee and payment options.",
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text('Cancel', style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => _AcceptOrderSheet(order: order),
                        );
                      },
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text('Yes, accept', style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.cream)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Parses the leading numeric part of a "1.2 km" style distance label.
double _parseKm(String dist) => double.tryParse(dist.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

/// A rough per-km delivery fee suggestion, rounded to the nearest 100 TZS.
int _suggestedFee(double km) => ((km * 3000) / 100).round() * 100;

Widget _sheetHandle() => Center(
  child: Container(
    width: 44,
    height: 5,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(99)),
  ),
);

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(text.toUpperCase(), style: AppText.eyebrow()),
  );
}

class _AcceptOrderSheet extends ConsumerStatefulWidget {
  const _AcceptOrderSheet({required this.order});
  final VendorOrder order;

  @override
  ConsumerState<_AcceptOrderSheet> createState() => _AcceptOrderSheetState();
}

class _AcceptOrderSheetState extends ConsumerState<_AcceptOrderSheet> {
  late final double _km = _parseKm(widget.order.dist);
  late final int _suggested = _suggestedFee(_km);
  late final _feeController = TextEditingController(text: _suggested.toString());
  final Set<String> _selectedMethodIds = {};
  String? _error;

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  void _toggleMethod(String id) {
    setState(() {
      if (!_selectedMethodIds.add(id)) _selectedMethodIds.remove(id);
    });
  }

  void _confirm() {
    final fee = _feeController.text.trim();
    if (fee.isEmpty || (double.tryParse(fee) ?? 0) <= 0) {
      setState(() => _error = 'Enter a valid delivery fee.');
      return;
    }
    if (_selectedMethodIds.isEmpty) {
      setState(() => _error = 'Select at least one payment method to offer.');
      return;
    }
    ref
        .read(vendorOrdersProvider.notifier)
        .acceptOrder(widget.order.id, VendorOrderAcceptance(fee: fee, paymentMethodIds: _selectedMethodIds.toList()));
    ref.read(notificationsProvider.notifier).addNotification(
      NotificationItem(
        initial: '✓',
        title: 'Order accepted',
        body: 'Marina Fresh Laundry accepted your order ${widget.order.id} · delivery fee ${formatTzs(double.parse(fee))}.',
        time: 'Just now',
        bg: AppColors.white,
        iconBg: AppColors.tealMuted,
        iconFg: AppColors.teal,
      ),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.order.id} accepted')));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final methods = ref.watch(vendorPaymentMethodsProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            decoration: const BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                Text('Accept ${order.id}', style: AppText.serif(fontSize: 22)),
                const SizedBox(height: 3),
                Text(
                  'Set a delivery fee and payment options for ${order.customer}',
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),

                const _SheetSectionLabel('Pickup location'),
                VendorPickupMapCard(
                  customerName: order.customer,
                  address: order.address,
                  distanceLabel: order.dist,
                  etaLabel: '~${(_km * 4).round().clamp(1, 999)} min',
                ),

                const _SheetSectionLabel('Delivery / pickup fee'),
                _FeeField(controller: _feeController, suggested: _suggested, km: _km),

                const _SheetSectionLabel('Payment methods to offer'),
                if (methods.isEmpty)
                  _NoPaymentMethodsNotice(
                    onGoToSettings: () {
                      Navigator.of(context).pop();
                      context.push('/vendor/settings');
                    },
                  )
                else
                  Column(
                    children: [
                      for (var i = 0; i < methods.length; i++) ...[
                        _PaymentMethodCheckTile(
                          method: methods[i],
                          selected: _selectedMethodIds.contains(methods[i].id),
                          onTap: () => _toggleMethod(methods[i].id),
                        ),
                        if (i != methods.length - 1) const SizedBox(height: 8),
                      ],
                    ],
                  ),

                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger)),
                ],

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: Text('Cancel', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 7,
                      child: Material(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _confirm,
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: Text(
                              'Confirm & accept',
                              style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeeField extends StatelessWidget {
  const _FeeField({required this.controller, required this.suggested, required this.km});

  final TextEditingController controller;
  final int suggested;
  final double km;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('TZS', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Enter fee',
                    hintStyle: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Suggested ${formatTzs(suggested)} based on ${km.toStringAsFixed(1)} km',
                  style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoPaymentMethodsNotice extends StatelessWidget {
  const _NoPaymentMethodsNotice({required this.onGoToSettings});
  final VoidCallback onGoToSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No saved payment method',
                  style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: const Color(0xFF8A5A12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "You have to set one up before you can offer payment options to clients.",
            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF8A5A12), height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onGoToSettings,
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Text('Add payment method', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A checkable row for one saved payout method — mirrors
/// `vendor_settings_screen.dart`'s `_PaymentMethodRow` look (logo/icon +
/// title/subtitle) but with a checkbox instead of Edit/Remove actions, since
/// here the vendor is choosing which methods to offer this client rather
/// than managing the saved list.
class _PaymentMethodCheckTile extends StatelessWidget {
  const _PaymentMethodCheckTile({required this.method, required this.selected, required this.onTap});

  final VendorPaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final provider = method.provider == null ? null : mobileProviderByName(method.provider!);
    final fallbackIcon = method.kind == VendorPaymentMethodKind.cashOnDelivery ? Icons.payments_outlined : Icons.account_balance_outlined;

    return Material(
      color: selected ? AppColors.tealMuted : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.teal : AppColors.creamDark, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (provider != null)
                MobileMoneyLogo(provider: provider, size: 36)
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(11)),
                  alignment: Alignment.center,
                  child: Icon(fallbackIcon, size: 17, color: AppColors.teal),
                ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.title, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(method.subtitle, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? AppColors.teal : Colors.white,
                  border: Border.all(color: selected ? AppColors.teal : const Color(0xFFD7D2C6), width: 1.8),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
