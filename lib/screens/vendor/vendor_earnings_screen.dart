import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/review_item.dart';
import '../../state/vendor_earnings_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';
import 'vendor_earnings_export.dart';

/// Donut segment colors per star level (5 → 1).
const _starColors = {
  5: AppColors.teal,
  4: Color(0xFF2A7D78),
  3: AppColors.amber,
  2: Color(0xFFE5A56B),
  1: AppColors.danger,
};

class VendorEarningsScreen extends ConsumerStatefulWidget {
  const VendorEarningsScreen({super.key});

  @override
  ConsumerState<VendorEarningsScreen> createState() => _VendorEarningsScreenState();
}

class _VendorEarningsScreenState extends ConsumerState<VendorEarningsScreen> {
  TrendRange _range = TrendRange.week;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vendorEarningsProvider.notifier).load());
  }

  Future<void> _export(bool asPdf) async {
    final state = ref.read(vendorEarningsProvider);
    setState(() => _exporting = true);
    try {
      if (asPdf) {
        await shareEarningsPdf(state, _range);
      } else {
        await shareEarningsImage(state, _range);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.creamDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Export summary', style: AppText.serif(fontSize: 19)),
              const SizedBox(height: 4),
              Text(
                'Breakdown, ${_range.label.toLowerCase()} trend, order list and ratings.',
                style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              _ExportTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Export as PDF',
                subtitle: 'Full summary document, ready to share or print',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _export(true);
                },
              ),
              const SizedBox(height: 10),
              _ExportTile(
                icon: Icons.image_outlined,
                title: 'Share as image',
                subtitle: 'PNG summary card for WhatsApp or status',
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  _export(false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorEarningsProvider);
    final orders = state.orderLines;
    final trend = state.trendFor(_range);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Row(
              children: [
                Expanded(child: Text('Earnings', style: AppText.serif(fontSize: 28))),
                _exporting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton.filledTonal(
                        onPressed: _showExportSheet,
                        tooltip: 'Export summary',
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                      ),
              ],
            ),
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

            // ── Earnings breakdown (no commission on this platform) ──
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
                  _MoneyLine(label: 'Paid out', value: '-${formatTzs(state.totalPayouts)}', valueColor: AppColors.amber),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: AppColors.creamDark)),
                  _MoneyLine(label: 'Net balance', value: formatTzs(state.balance), bold: true, valueColor: AppColors.teal),
                ],
              ),
            ),

            // ── Order-amount trend ───────────────────────────────────
            const _SectionLabel('Earnings trend'),
            _TrendCard(
              range: _range,
              points: trend,
              isLoading: state.isLoading,
              onRange: (r) => setState(() => _range = r),
            ),

            // ── Orders (per completed order, each with amount) ───────
            _SectionLabel('Orders (${orders.length})'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: orders.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          state.isLoading ? '' : 'No completed orders yet — amounts appear here when orders are delivered.',
                          textAlign: TextAlign.center,
                          style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < orders.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: i == orders.length - 1 ? Colors.transparent : AppColors.cream)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.tealMuted,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 18,
                                    color: AppColors.teal,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        orders[i].label,
                                        style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        orders[i].sub,
                                        style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${formatTzs(orders[i].amountTzs)}',
                                  style: AppText.sans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),

            // ── Reviews & ratings ────────────────────────────────────
            const _SectionLabel('Reviews & ratings'),
            _RatingsCard(state: state),
            if (state.reviews.isNotEmpty) ...[
              const SizedBox(height: 10),
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
}

// ── Export sheet tile ──────────────────────────────────────────────────

class _ExportTile extends StatelessWidget {
  const _ExportTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Trend card ─────────────────────────────────────────────────────────

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.range, required this.points, required this.isLoading, required this.onRange});

  final TrendRange range;
  final List<TrendPoint> points;
  final bool isLoading;
  final ValueChanged<TrendRange> onRange;

  double get _total => points.fold(0, (s, p) => s + p.amountTzs);

  /// Second-half vs first-half change, null when there is no baseline.
  double? get _changePct {
    if (points.length < 2) return null;
    final half = points.length ~/ 2;
    final first = points.take(half).fold<double>(0, (s, p) => s + p.amountTzs);
    final second = points.skip(half).fold<double>(0, (s, p) => s + p.amountTzs);
    if (first <= 0) return second > 0 ? 100 : null;
    return (second - first) / first * 100;
  }

  @override
  Widget build(BuildContext context) {
    final pct = _changePct;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ORDER AMOUNTS', style: AppText.eyebrow()),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            formatTzs(_total),
                            style: AppText.serif(fontSize: 24),
                          ),
                        ),
                        if (pct != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(bottom: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: pct >= 0 ? AppColors.successLight : AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                              style: AppText.sans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: pct >= 0 ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final r in TrendRange.values)
                      GestureDetector(
                        onTap: () => onRange(r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: r == range ? AppColors.teal : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            r.label,
                            style: AppText.sans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: r == range ? Colors.white : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading && _total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text(
                  'No order amounts in this period yet.',
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
            )
          else
            _TrendChart(points: points),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});
  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final max = points.fold<double>(0, (m, p) => p.amountTzs > m ? p.amountTzs : m);
    return Column(
      children: [
        SizedBox(
          height: 130,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(
              values: [for (final p in points) max == 0 ? 0.0 : (p.amountTzs / max).clamp(0.0, 1.0)],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in _axisLabels())
              Text(label, style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
          ],
        ),
      ],
    );
  }

  /// First / middle / last labels so the axis stays readable on all ranges.
  List<String> _axisLabels() {
    if (points.isEmpty) return const [];
    if (points.length <= 3) return [for (final p in points) p.label];
    return [
      points.first.label,
      points[points.length ~/ 2].label,
      points.last.label,
    ];
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.values});
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    // Faint gridlines.
    final grid = Paint()
      ..color = AppColors.creamDark
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = pad + h * i / 2;
      canvas.drawLine(Offset(pad, y), Offset(pad + w, y), grid);
    }

    Offset pointAt(int i) {
      final x = values.length == 1 ? pad + w / 2 : pad + w * i / (values.length - 1);
      final y = pad + h * (1 - values[i].clamp(0.0, 1.0));
      return Offset(x, y);
    }

    // Smooth curve through midpoints (quadratic bezier).
    final line = Path();
    if (values.length == 1) {
      line.moveTo(pad, pointAt(0).dy);
      line.lineTo(pad + w, pointAt(0).dy);
    } else {
      line.moveTo(pointAt(0).dx, pointAt(0).dy);
      for (var i = 0; i < values.length - 1; i++) {
        final p0 = pointAt(i);
        final p1 = pointAt(i + 1);
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        line.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      line.lineTo(pointAt(values.length - 1).dx, pointAt(values.length - 1).dy);
    }

    // Area fill under the curve.
    final fill = Path.from(line)
      ..lineTo(values.length == 1 ? pad + w : pointAt(values.length - 1).dx, pad + h)
      ..lineTo(pad, pad + h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.teal.withValues(alpha: 0.28), AppColors.teal.withValues(alpha: 0.02)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // End dot.
    final end = values.length == 1 ? Offset(pad + w / 2, pointAt(0).dy) : pointAt(values.length - 1);
    canvas.drawCircle(end, 5, Paint()..color = Colors.white);
    canvas.drawCircle(
      end,
      5,
      Paint()
        ..color = AppColors.teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(end, 2, Paint()..color = AppColors.teal);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.values != values;
}

// ── Ratings card ───────────────────────────────────────────────────────

class _RatingsCard extends StatelessWidget {
  const _RatingsCard({required this.state});
  final VendorEarningsState state;

  @override
  Widget build(BuildContext context) {
    final counts = state.starCounts;
    final total = state.reviews.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(22),
      ),
      child: total == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No reviews yet — ratings appear here once customers rate your shop.',
                  textAlign: TextAlign.center,
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 128,
                      height: 128,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(128, 128),
                            painter: _DonutPainter(counts: counts, total: total),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.avgRating.toStringAsFixed(1),
                                style: AppText.serif(fontSize: 26),
                              ),
                              Text(
                                '$total review${total == 1 ? '' : 's'}',
                                style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          for (var s = 5; s >= 1; s--)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3.5),
                              child: Row(
                                children: [
                                  Icon(Icons.star_rounded, size: 15, color: _starColors[s]),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$s',
                                    style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: total == 0 ? 0 : (counts[s] ?? 0) / total,
                                        minHeight: 7,
                                        backgroundColor: AppColors.cream,
                                        valueColor: AlwaysStoppedAnimation<Color>(_starColors[s]!),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 58,
                                    child: Text(
                                      '${counts[s] ?? 0} order${(counts[s] ?? 0) == 1 ? '' : 's'}',
                                      textAlign: TextAlign.right,
                                      style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.counts, required this.total});
  final Map<int, int> counts;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const stroke = 17.0;
    // Track.
    canvas.drawArc(
      rect.deflate(stroke / 2),
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.cream
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );
    if (total == 0) return;
    var start = -math.pi / 2;
    for (var s = 5; s >= 1; s--) {
      final frac = (counts[s] ?? 0) / total;
      if (frac <= 0) continue;
      // Small gap between segments.
      const gap = 0.035;
      final sweep = math.max(frac * math.pi * 2 - gap, 0.02);
      canvas.drawArc(
        rect.deflate(stroke / 2),
        start + gap / 2,
        sweep,
        false,
        Paint()
          ..color = _starColors[s]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += frac * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.counts != counts || old.total != total;
}

// ── Shared bits ────────────────────────────────────────────────────────

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
