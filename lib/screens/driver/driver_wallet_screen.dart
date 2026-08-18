import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/driver_mock_data.dart';
import '../../state/driver_wallet_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class DriverWalletScreen extends ConsumerWidget {
  const DriverWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutDone = ref.watch(driverWalletProvider);
    final notifier = ref.read(driverWalletProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              child: Container(
                color: AppColors.teal,
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -60,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WITHDRAWABLE BALANCE', style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.6))),
                        const SizedBox(height: 6),
                        Text('TZS 1,073,280', style: AppText.serif(fontSize: 40, color: AppColors.cream)),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Material(
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: notifier.requestPayout,
                                child: Container(
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  alignment: Alignment.center,
                                  child: Text(
                                    payoutDone ? '✓ Payout requested' : 'Request payout',
                                    style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Next auto payout\nFriday, 15 Aug',
                                style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.cream.withValues(alpha: 0.62), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 11),
              child: Text('THIS WEEK', style: AppText.eyebrow()),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const _LegendDot(color: AppColors.success, label: 'Completed'),
                      const SizedBox(width: 16),
                      const _LegendDot(color: AppColors.rust, label: 'Cancelled'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _WeekChart(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 11),
              child: Text('TRIP BREAKDOWN', style: AppText.eyebrow()),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 26),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < kDriverLedger.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: i == kDriverLedger.length - 1 ? Colors.transparent : AppColors.cream)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(kDriverLedger[i].id, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                              Text(kDriverLedger[i].total, style: AppText.serif(fontSize: 17, color: AppColors.teal)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${kDriverLedger[i].date} · ${kDriverLedger[i].km}',
                                style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                              ),
                              Text(
                                'Base ${kDriverLedger[i].base} · Tip ${kDriverLedger[i].tip}',
                                style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

/// The "This week" dual-bar chart: two independent narrow bars per day
/// (completed vs cancelled), not a single stacked bar — a different shape
/// from the [BarChartRow] used elsewhere, so kept local to this screen.
class _WeekChart extends StatelessWidget {
  const _WeekChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < kDriverWeek.length; i++) ...[
            if (i != 0) const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 96,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 8,
                          height: 96 * kDriverWeek[i].$2,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Container(
                          width: 8,
                          height: 96 * kDriverWeek[i].$3,
                          decoration: const BoxDecoration(
                            color: AppColors.rust,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(kDriverWeek[i].$1, style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.tabInactive)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
