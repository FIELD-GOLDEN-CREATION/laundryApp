import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/vendor_mock_data.dart';
import '../../models/track_step_def.dart';
import '../../state/vendor_order_detail_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/vendor_pickup_map_card.dart';

class VendorOrderDetailScreen extends ConsumerWidget {
  const VendorOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorOrderDetailProvider);
    final notifier = ref.read(vendorOrderDetailProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Row(
              children: [
                RoundBackButton(onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #LD-2481', style: AppText.serif(fontSize: 23)),
                    const SizedBox(height: 2),
                    Text(
                      'Amara Reed · 8 items',
                      style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
            const _SectionLabel('Packages & services selected'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < kOrderLineItems.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: i == kOrderLineItems.length - 1 ? Colors.transparent : AppColors.cream),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${kOrderLineItems[i].qty}× ${kOrderLineItems[i].name}',
                              style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            formatTzs(kOrderLineItems[i].total),
                            style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const _SectionLabel('Map & navigation'),
            VendorPickupMapCard(
              customerName: 'Amara Reed',
              address: '12 Chole Road, Masaki, Apt 4B',
              distanceLabel: '1.2 km',
              etaLabel: '~4 min',
              onGetDirections: () {},
            ),
            const _SectionLabel('Processing status'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < kProcessingSteps.length; i++)
                    _ProcessStepRow(
                      step: kProcessingSteps[i],
                      done: i <= state.step,
                      onTap: () => notifier.pickStep(i),
                    ),
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
      padding: const EdgeInsets.only(top: 24, bottom: 11),
      child: Text(text.toUpperCase(), style: AppText.eyebrow()),
    );
  }
}

class _ProcessStepRow extends StatelessWidget {
  const _ProcessStepRow({required this.step, required this.done, required this.onTap});

  final TrackStepDef step;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.teal : Colors.white,
                  border: Border.all(color: done ? AppColors.teal : const Color(0xFFD7D2C6), width: 2),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.cream : const Color(0xFFD7D2C6)),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  step.title,
                  style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: done ? AppColors.slate : AppColors.muted),
                ),
              ),
              Text(
                done ? step.time : 'Pending',
                style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
