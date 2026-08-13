import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_mock_data.dart';
import '../../models/report_metric.dart';
import '../../state/admin_reports_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/bar_chart_row.dart';
import '../../widgets/selectable_chip.dart';
import '../../widgets/thin_progress_bar.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReportsProvider);
    final notifier = ref.read(adminReportsProvider.notifier);
    final scope = '${kAgentLabels[state.agent]} · ${kPeriodScopeLabels[state.period]}';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          children: [
            Text('Reporting', style: AppText.serif(fontSize: 27)),
            const SizedBox(height: 6),
            Text(scope, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted)),
            const _SectionLabel('Agent / staff'),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kAgentLabels.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => SelectableChip(
                  label: kAgentLabels[i],
                  selected: state.agent == i,
                  onTap: () => notifier.pickAgent(i),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Text('PERIOD', style: AppText.eyebrow()),
            ),
            Row(
              children: [
                for (var i = 0; i < kPeriodLabels.length; i++) ...[
                  if (i != 0) const SizedBox(width: 8),
                  Expanded(
                    child: SelectableChip(
                      label: kPeriodLabels[i],
                      selected: state.period == i,
                      onTap: () => notifier.pickPeriod(i),
                      variant: ChipVariant.muted,
                      borderRadius: 12,
                      fontSize: 12,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Column(
              children: [
                for (var i = 0; i < kReportMetrics.length; i++) ...[
                  _MetricCard(metric: kReportMetrics[i]),
                  if (i != kReportMetrics.length - 1) const SizedBox(height: 11),
                ],
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orders vs cancellations', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                  const SizedBox(height: 14),
                  BarChartRow(
                    height: 88,
                    gap: 7,
                    bars: [
                      for (var i = 0; i < kReportBarFractions.length; i++)
                        BarDatum(
                          heightFraction: kReportBarFractions[i],
                          color: AppColors.tealMuted,
                          stackedFraction: kReportBarFractions[i] * 0.12,
                          stackedColor: AppColors.amber,
                          label: kReportBarLabels[i],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: notifier.exportReport,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  alignment: Alignment.center,
                  child: Text(
                    state.exported ? '✓ Report exported as PDF' : 'Export report as PDF',
                    style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.cream),
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
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(text.toUpperCase(), style: AppText.eyebrow()),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final ReportMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label.toUpperCase(),
                      style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(metric.value, style: AppText.serif(fontSize: 30)),
                        const SizedBox(width: 8),
                        Text(metric.pct, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: metric.pctFg)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  metric.note,
                  textAlign: TextAlign.right,
                  style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ThinProgressBar(fraction: metric.bar, fillColor: metric.pctFg),
        ],
      ),
    );
  }
}
