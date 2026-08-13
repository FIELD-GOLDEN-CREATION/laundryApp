import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/vendor_mock_data.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/account_sheet.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/bar_chart_row.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/thin_progress_bar.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onAccount: () => showAccountSheet(context, ref)),
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(child: StatTile(value: '7', label: 'Pending orders', bg: Colors.white, fg: AppColors.teal)),
                    SizedBox(width: 10),
                    Expanded(child: _MachinesBusyTile()),
                    SizedBox(width: 10),
                    Expanded(child: StatTile(value: '2', label: 'Urgent', bg: AppColors.amberLight, fg: AppColors.amber)),
                  ],
                ),
              ),
              const _SectionLabel('Needs attention now'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    for (var i = 0; i < kVendorAlerts.length; i++) ...[
                      AlertCard(
                        title: kVendorAlerts[i].title,
                        sub: kVendorAlerts[i].sub,
                        tag: kVendorAlerts[i].tag,
                        accentColor: kVendorAlerts[i].accentColor,
                        tagBg: kVendorAlerts[i].tagBg,
                        onTap: () => context.push('/vendor/order-detail'),
                      ),
                      if (i != kVendorAlerts.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const _SectionLabel('Machine capacity'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.creamDark),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < kMachines.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: i == kMachines.length - 1 ? Colors.transparent : AppColors.cream,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(kMachines[i].name, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                Text(
                                  kMachines[i].state,
                                  style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: kMachines[i].color),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            ThinProgressBar(fraction: kMachines[i].pct, fillColor: kMachines[i].color),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAccount});

  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        color: AppColors.teal,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -70,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WEDNESDAY, 12 AUG', style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.6))),
                        const SizedBox(height: 6),
                        Text('Marina Fresh Laundry', style: AppText.serif(fontSize: 25, color: AppColors.cream)),
                      ],
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onAccount,
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Center(child: Text('V', style: AppText.serif(fontSize: 17, color: AppColors.cream))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REVENUE TODAY', style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.62))),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('TZS 1,264,120', style: AppText.serif(fontSize: 34, color: AppColors.cream)),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              '▲ 12% vs Tue',
                              style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.mint),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      BarChartRow(
                        height: 38,
                        gap: 6,
                        bars: [
                          for (var i = 0; i < kWeekBarFractions.length; i++)
                            BarDatum(
                              heightFraction: kWeekBarFractions[i],
                              color: i == 6 ? AppColors.amber : Colors.white.withValues(alpha: 0.34),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MachinesBusyTile extends StatelessWidget {
  const _MachinesBusyTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '6', style: AppText.serif(fontSize: 24, color: AppColors.teal)),
                TextSpan(text: '/8', style: AppText.serif(fontSize: 15, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text('Machines busy', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
        ],
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
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 11),
      child: Text(text.toUpperCase(), style: AppText.eyebrow()),
    );
  }
}
