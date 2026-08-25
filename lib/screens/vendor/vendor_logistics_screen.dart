import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/day_option.dart';
import '../../state/vendor_order_detail_state.dart';
import '../../state/vendor_logistics_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/barcode_strip.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/thin_progress_bar.dart';

/// Pure UI config — the return-delivery day strip has no API backing.
const _kReturnDays = [
  DayOption(dow: 'Thu', num: '13'),
  DayOption(dow: 'Fri', num: '14'),
  DayOption(dow: 'Sat', num: '15'),
  DayOption(dow: 'Sun', num: '16'),
  DayOption(dow: 'Mon', num: '17'),
];

class VendorLogisticsScreen extends ConsumerWidget {
  const VendorLogisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorLogisticsProvider);
    final notifier = ref.read(vendorLogisticsProvider.notifier);
    final tagId = ref.watch(vendorOrderDetailProvider.select((s) => s.tagId));

    final driverDist = '${((100 - state.driverPct) * 18).round()} m';
    final driverEta = '${max(1, ((100 - state.driverPct) / 12).round())} min';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Driver handoff', style: AppText.serif(fontSize: 28)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 48, height: 48, child: PlaceholderImage(label: 'Driver', circle: true)),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daniel O.', style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                              '$driverDist away · arriving in $driverEta',
                              style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(999)),
                        child: Text('En route', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.teal)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ThinProgressBar(fraction: state.driverPct / 100, fillColor: AppColors.teal),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('LEFT DEPOT', style: AppText.eyebrow()),
                      Text('AT YOUR DOOR', style: AppText.eyebrow()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DashedButton(label: 'Demo: move driver closer', onTap: notifier.moveDriverCloser),
                ],
              ),
            ),
            const _SectionLabel('Barcode handoff'),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: state.scanned ? AppColors.tealMuted : Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const BarcodeStrip(height: 56),
                  const SizedBox(height: 10),
                  Text(
                    tagId,
                    style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: state.scanned ? AppColors.tealMuted : AppColors.slate,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: notifier.toggleScanned,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        alignment: Alignment.center,
                        child: Text(
                          state.scanned ? '✓ Handoff validated · 6:02 PM' : 'Scan to validate handoff',
                          style: AppText.sans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: state.scanned ? AppColors.teal : AppColors.cream,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _SectionLabel('Proof of delivery'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 130, width: double.infinity, child: PlaceholderImage(label: 'Courier drop-off photo', borderRadius: 16)),
                  const SizedBox(height: 13),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                          children: const [
                            TextSpan(text: 'Signed by '),
                            TextSpan(text: 'A. Reed', style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Text('Thu, 6:04 PM', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                    ],
                  ),
                ],
              ),
            ),
            const _SectionLabel('Schedule return delivery'),
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _kReturnDays.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (_, i) {
                  final active = state.returnDay == i;
                  return _DayChip(
                    dow: _kReturnDays[i].dow,
                    num: _kReturnDays[i].num,
                    active: active,
                    onTap: () => notifier.pickReturnDay(i),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Material(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: notifier.scheduleReturn,
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  child: Text(
                    state.returnSet ? '✓ Return delivery scheduled' : 'Schedule return delivery',
                    style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.cream),
                  ),
                ),
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

class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(border: Border.all(color: AppColors.creamDark, width: 1.5), borderRadius: BorderRadius.circular(14)),
          child: Center(
            child: Text(label, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.dow, required this.num, required this.active, required this.onTap});
  final String dow;
  final String num;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.teal : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: active ? AppColors.teal : AppColors.creamDark, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Column(
              children: [
                Text(dow, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: (active ? AppColors.cream : AppColors.slate).withValues(alpha: 0.75))),
                const SizedBox(height: 3),
                Text(num, style: AppText.sans(fontSize: 18, fontWeight: FontWeight.w800, color: active ? AppColors.cream : AppColors.slate)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
