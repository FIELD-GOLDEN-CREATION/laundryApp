import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/review_item.dart';
import '../../state/vendor_earnings_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';
import '../../widgets/bar_chart_row.dart';

class VendorEarningsScreen extends ConsumerStatefulWidget {
  const VendorEarningsScreen({super.key});

  @override
  ConsumerState<VendorEarningsScreen> createState() => _VendorEarningsScreenState();
}

class _VendorEarningsScreenState extends ConsumerState<VendorEarningsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vendorEarningsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorEarningsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Earnings', style: AppText.serif(fontSize: 28)),
            const SizedBox(height: 20),

            // ── Balance card ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.teal, Color(0xFF0F3D3A)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AVAILABLE BALANCE', style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.62))),
                  const SizedBox(height: 6),
                  state.isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mint),
                        )
                      : Text(formatTzs(state.balance), style: AppText.serif(fontSize: 38, color: AppColors.cream)),
                  if (state.pendingPayouts > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${formatTzs(state.pendingPayouts)} pending payout',
                      style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.cream.withValues(alpha: 0.72)),
                    ),
                  ],
                ],
              ),
            ),

            // ── Earnings breakdown ───────────────────────────────────
            const _SectionLabel('Earnings breakdown'),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  _MoneyLine(label: 'Gross revenue', value: formatTzs(state.totalRevenue)),
                  const SizedBox(height: 9),
                  _MoneyLine(label: 'Platform commission', value: '-${formatTzs(state.totalCommission)}', valueColor: AppColors.amber),
                  const SizedBox(height: 9),
                  _MoneyLine(label: 'Paid out', value: '-${formatTzs(state.totalPayouts)}', valueColor: AppColors.amber),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: AppColors.creamDark)),
                  _MoneyLine(label: 'Net balance', value: formatTzs(state.balance), bold: true, valueColor: AppColors.teal),
                ],
              ),
            ),

            // ── Monthly payout trend ─────────────────────────────────
            const _SectionLabel('Payout trends'),
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: state.monthBars.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          state.isLoading ? '' : 'No payout history yet.',
                          style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.slate, borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formatTzs(_peakAmount(state)), style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                              Text('best month', style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        BarChartRow(
                          height: 130,
                          gap: 10,
                          barRadius: 6,
                          bars: [
                            for (var i = 0; i < state.monthBars.length; i++)
                              BarDatum(
                                heightFraction: state.monthBars[i].fraction,
                                color: i == state.monthBars.length - 1 ? AppColors.teal : AppColors.teal.withValues(alpha: 0.35),
                                label: state.monthBars[i].label,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),

            // ── Payout history ───────────────────────────────────────
            const _SectionLabel('Payout history'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: state.payouts.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          state.isLoading ? '' : 'No payouts recorded yet.',
                          style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < state.payouts.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: i == state.payouts.length - 1 ? Colors.transparent : AppColors.cream)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(12)),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.account_balance_rounded, size: 18, color: AppColors.teal),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.payouts[i].dateLabel.isEmpty ? state.payouts[i].status : state.payouts[i].dateLabel,
                                        style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          if (state.payouts[i].method.isNotEmpty) state.payouts[i].method,
                                          if (state.payouts[i].reference.isNotEmpty) state.payouts[i].reference,
                                        ].join(' · '),
                                        style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(formatTzs(state.payouts[i].amountTzs), style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal)),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),

            // ── Reviews & ratings (only when a shop id resolves) ─────
            if (state.reviews.isNotEmpty) ...[
              const _SectionLabel('Reviews & ratings'),
              for (var i = 0; i < state.reviews.length; i++) ...[
                _ReviewCard(review: state.reviews[i]),
                if (i != state.reviews.length - 1) const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  double _peakAmount(VendorEarningsState state) =>
      state.monthBars.fold(0, (m, b) => b.amountTzs > m ? b.amountTzs : m);
}

// ── Widgets ────────────────────────────────────────────────────────────

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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ReviewItem review;

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
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  review.name.isNotEmpty ? review.name[0] : '?',
                  style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.name, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Icon(
                            i < review.stars.length ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 13,
                            color: AppColors.amber,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.text,
            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
