import 'package:flutter/material.dart';

import '../../data/vendor_mock_data.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/bar_chart_row.dart';

class VendorEarningsScreen extends StatelessWidget {
  const VendorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Earnings', style: AppText.serif(fontSize: 28)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AVAILABLE BALANCE', style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.62))),
                  const SizedBox(height: 6),
                  Text('TZS 8,171,280', style: AppText.serif(fontSize: 38, color: AppColors.cream)),
                  const SizedBox(height: 4),
                  Text(
                    'Next payout Friday, 14 Aug',
                    style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.cream.withValues(alpha: 0.72)),
                  ),
                ],
              ),
            ),
            const _SectionLabel('This month at a glance'),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  BarChartRow(
                    height: 110,
                    gap: 9,
                    bars: [
                      for (var i = 0; i < kMonthBars.length; i++)
                        BarDatum(
                          heightFraction: kMonthBars[i].$2,
                          color: i == kMonthBars.length - 1 ? AppColors.teal : AppColors.tealMuted,
                          label: kMonthBars[i].$1,
                        ),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Divider(height: 1, color: AppColors.cream)),
                  const _MoneyLine(label: 'Gross revenue', value: 'TZS 10,712,000'),
                  const SizedBox(height: 9),
                  const _MoneyLine(label: 'Platform commission (15%)', value: '−TZS 1,606,800', valueColor: AppColors.amber),
                  const SizedBox(height: 9),
                  const _MoneyLine(label: 'Detergent & supplies', value: '−TZS 933,920', valueColor: AppColors.amber),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Divider(height: 1, color: AppColors.creamDark)),
                  const _MoneyLine(label: 'Net earnings', value: 'TZS 8,171,280', bold: true, valueColor: AppColors.teal),
                ],
              ),
            ),
            const _SectionLabel('Payout history'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < kPayouts.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: i == kPayouts.length - 1 ? Colors.transparent : AppColors.cream)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(kPayouts[i].date, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(
                                  kPayouts[i].ref,
                                  style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Text(kPayouts[i].amount, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const _SectionLabel('Latest reviews'),
            Column(
              children: [
                for (var i = 0; i < kReviews.length; i++) ...[
                  Container(
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
                            Text(kReviews[i].name, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                            Text(kReviews[i].stars, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.amber)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          kReviews[i].text,
                          style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  if (i != kReviews.length - 1) const SizedBox(height: 11),
                ],
              ],
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

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.label, required this.value, this.bold = false, this.valueColor = AppColors.slate});

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
          style: AppText.sans(fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w700, color: bold ? AppColors.slate : AppColors.muted),
        ),
        Text(value, style: AppText.sans(fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w700, color: valueColor)),
      ],
    );
  }
}
