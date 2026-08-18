import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_mock_data.dart';
import '../../models/admin_order_row.dart';
import '../../models/modal_copy.dart';
import '../../models/vendor_load_card.dart';
import '../../state/admin_orders_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/crud_form_modal.dart';
import '../../widgets/selectable_chip.dart';
import '../../widgets/thin_progress_bar.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  // Matches AdminOrdersState's own defaults (state/admin_orders_state.dart).
  final _fromController = TextEditingController(text: '06 Aug 2026');
  final _toController = TextEditingController(text: '12 Aug 2026');

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminOrdersProvider, (prev, next) {
      if (_fromController.text != next.dateFrom) _fromController.text = next.dateFrom;
      if (_toController.text != next.dateTo) _toController.text = next.dateTo;
    });
    final state = ref.watch(adminOrdersProvider);
    final notifier = ref.read(adminOrdersProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orders hub', style: AppText.serif(fontSize: 27)),
                  const SizedBox(height: 6),
                  Text(
                    '${kAdminOrders.length} orders match the current filter',
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                itemCount: kRangeChipLabels.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (_, i) => SelectableChip(
                  label: kRangeChipLabels[i],
                  selected: state.range == i,
                  onTap: () => notifier.pickRange(i),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
              child: Row(
                children: [
                  Expanded(child: _DateBox(label: 'FROM', controller: _fromController, onChanged: notifier.setDateFrom)),
                  const SizedBox(width: 10),
                  Expanded(child: _DateBox(label: 'TO', controller: _toController, onChanged: notifier.setDateTo)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                itemCount: kHourChipLabels.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => SelectableChip(
                  label: kHourChipLabels[i],
                  selected: state.hour == i,
                  onTap: () => notifier.pickHour(i),
                  variant: ChipVariant.muted,
                  borderRadius: 10,
                  fontSize: 11.5,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                ),
              ),
            ),
            const _SectionLabel('Vendor load right now'),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                itemCount: kVendorLoads.length,
                separatorBuilder: (_, _) => const SizedBox(width: 11),
                itemBuilder: (_, i) => _VendorLoadTile(card: kVendorLoads[i], onTap: () => context.push('/admin/vendor')),
              ),
            ),
            const _SectionLabel('Order grid'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  for (var i = 0; i < kAdminOrders.length; i++) ...[
                    _AdminOrderCard(order: kAdminOrders[i]),
                    if (i != kAdminOrders.length - 1) const SizedBox(height: 11),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 11),
      child: Text(text.toUpperCase(), style: AppText.eyebrow()),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.label, required this.controller, required this.onChanged});
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: AppColors.muted)),
          const SizedBox(height: 3),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800),
            decoration: const InputDecoration.collapsed(hintText: ''),
          ),
        ],
      ),
    );
  }
}

class _VendorLoadTile extends StatelessWidget {
  const _VendorLoadTile({required this.card, required this.onTap});
  final VendorLoadCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = card.over ? AppColors.amberLight : Colors.white;
    final border = card.over ? const Color(0xFFF3E1C2) : AppColors.creamDark;
    final fg = card.over ? AppColors.amber : AppColors.slate;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 168,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.name, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(card.volume, style: AppText.serif(fontSize: 23, color: AppColors.teal)),
                  const SizedBox(width: 6),
                  Text('orders today', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 10),
              ThinProgressBar(fraction: card.pct, fillColor: card.over ? AppColors.amber : AppColors.teal, height: 6),
              const SizedBox(height: 7),
              Text(card.queue, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: card.over ? AppColors.amber : AppColors.teal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order});
  final AdminOrderRow order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.id, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: order.statusBg, borderRadius: BorderRadius.circular(999)),
                child: Text(order.status, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: order.statusFg)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9,
            crossAxisSpacing: 12,
            childAspectRatio: 3.2,
            children: [
              for (final f in order.fields)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.key.toUpperCase(), style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.tabInactive)),
                    const SizedBox(height: 2),
                    Text(f.value, style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _ActionButton(label: 'Reassign', filled: false, onTap: () => showCrudFormModal(context, ModalKind.reassign))),
              const SizedBox(width: 8),
              Expanded(child: _ActionButton(label: 'Refund', filled: false, amber: true, onTap: () => showCrudFormModal(context, ModalKind.refund))),
              const SizedBox(width: 8),
              Expanded(child: _ActionButton(label: 'Contact', filled: true, onTap: () => showCrudFormModal(context, ModalKind.contact))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.filled, required this.onTap, this.amber = false});
  final String label;
  final bool filled;
  final bool amber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.cream : (amber ? AppColors.amber : AppColors.teal);
    return Material(
      color: filled ? AppColors.teal : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: filled ? AppColors.teal : AppColors.creamDark)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Center(child: Text(label, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: fg))),
        ),
      ),
    );
  }
}
