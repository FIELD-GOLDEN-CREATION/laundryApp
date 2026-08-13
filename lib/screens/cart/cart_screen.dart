import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_data.dart';
import '../../models/menu_item.dart';
import '../../state/cart_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_cta_bar.dart';
import '../../widgets/round_back_button.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final lines = kMenuItems.where((i) => (qty[i.key] ?? 0) > 0).toList();
    final subtotal = cartSubtotal(qty);

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
                  Text('Your basket', style: AppText.serif(fontSize: 24)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Marina Fresh Laundry · ${cartItemCount(qty)} items',
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
              ),
              Column(
                children: [
                  for (final item in lines) ...[
                    _CartRow(item: item, qty: qty[item.key] ?? 0, notifier: notifier),
                    if (item != lines.last) const SizedBox(height: 11),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.push('/detail'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.creamDark, width: 1.5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        '+ Add more items',
                        style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                      ),
                    ),
                  ),
                ),
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
                    _SummaryLine(label: 'Subtotal', value: formatMoney(subtotal)),
                    const SizedBox(height: 9),
                    const _SummaryLine(label: 'Pickup & delivery', value: 'Free', valueColor: AppColors.teal),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Divider(height: 1, color: AppColors.creamDark),
                    ),
                    _SummaryLine(
                      label: 'Total',
                      value: formatMoney(subtotal),
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
        label: 'Schedule pickup',
        hint: formatMoney(subtotal),
        onPressed: () => context.push('/schedule'),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item, required this.qty, required this.notifier});

  final MenuItem item;
  final int qty;
  final CartNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Text(item.initial, style: AppText.serif(fontSize: 17, color: AppColors.teal)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${item.unit} · ${formatMoney(item.price)}',
                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(999)),
            child: Row(
              children: [
                _StepButton(symbol: '−', bg: Colors.white, fg: AppColors.teal, onTap: () => notifier.setQty(item.key, -1)),
                SizedBox(
                  width: 26,
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                ),
                _StepButton(symbol: '+', bg: AppColors.teal, fg: Colors.white, onTap: () => notifier.setQty(item.key, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.symbol, required this.bg, required this.fg, required this.onTap});

  final String symbol;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: Text(symbol, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w800, height: 1)),
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value, this.bold = false, this.valueColor = AppColors.slate});

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
          style: AppText.sans(fontSize: bold ? 16 : 13.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w700, color: bold ? AppColors.slate : AppColors.muted),
        ),
        Text(
          value,
          style: AppText.sans(fontSize: bold ? 16 : 13.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w700, color: valueColor),
        ),
      ],
    );
  }
}
