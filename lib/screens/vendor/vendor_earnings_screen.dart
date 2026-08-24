import 'package:flutter/material.dart';

import '../../data/vendor_mock_data.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';

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
                  Text('TZS 8,171,280', style: AppText.serif(fontSize: 38, color: AppColors.cream)),
                  const SizedBox(height: 4),
                  Text(
                    'Next payout Friday, 14 Aug',
                    style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.cream.withValues(alpha: 0.72)),
                  ),
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
                  _EarningCategory(
                    icon: Icons.local_shipping_outlined,
                    label: 'Delivery fees',
                    amount: 486000,
                    total: 10712000,
                    color: AppColors.teal,
                  ),
                  const SizedBox(height: 14),
                  _EarningCategory(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Add-on & upsell',
                    amount: 1824000,
                    total: 10712000,
                    color: AppColors.amber,
                  ),
                  const SizedBox(height: 14),
                  _EarningCategory(
                    icon: Icons.store_outlined,
                    label: 'Pickup & self-drop',
                    amount: 3216000,
                    total: 10712000,
                    color: AppColors.mint,
                  ),
                  const SizedBox(height: 14),
                  _EarningCategory(
                    icon: Icons.receipt_long_rounded,
                    label: 'Order service',
                    amount: 5186000,
                    total: 10712000,
                    color: AppColors.slate,
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: AppColors.cream)),
                  _MoneyLine(label: 'Gross revenue', value: formatTzs(10712000)),
                  const SizedBox(height: 9),
                  _MoneyLine(label: 'Platform commission (15%)', value: '-${formatTzs(1606800)}', valueColor: AppColors.amber),
                  const SizedBox(height: 9),
                  _MoneyLine(label: 'Detergent & supplies', value: '-${formatTzs(933920)}', valueColor: AppColors.amber),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: AppColors.creamDark)),
                  _MoneyLine(label: 'Net earnings', value: formatTzs(8171280), bold: true, valueColor: AppColors.teal),
                ],
              ),
            ),

            // ── Sales trend line chart ───────────────────────────────
            const _SectionLabel('Sales trends'),
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.fromLTRB(14, 20, 18, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tooltip
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.slate,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatTzs(20000), style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text('Wednesday', style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 150,
                    child: CustomPaint(
                      size: const Size(double.infinity, 150),
                      painter: _LineChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Y-axis labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final label in ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'])
                        Text(label, style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted)),
                    ],
                  ),
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
                                Text(kPayouts[i].date, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(kPayouts[i].ref, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
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

            // ── Reviews & ratings ────────────────────────────────────
            const _SectionLabel('Reviews & ratings'),
            // Average rating summary
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  // Big rating number
                  Column(
                    children: [
                      Text('4.9', style: AppText.serif(fontSize: 42, color: AppColors.amber)),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) => Icon(
                          i < 5 ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 16,
                          color: AppColors.amber,
                        )),
                      ),
                      const SizedBox(height: 4),
                      Text('${kReviews.length} reviews', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Rating bars
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = 5; i >= 1; i--)
                          _RatingBar(star: i, fraction: i == 5 ? 0.78 : i == 4 ? 0.15 : i == 3 ? 0.05 : 0.02),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Individual reviews
            Column(
              children: [
                for (var i = 0; i < kReviews.length; i++) ...[
                  _ReviewCard(review: kReviews[i]),
                  if (i != kReviews.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
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

class _EarningCategory extends StatelessWidget {
  const _EarningCategory({
    required this.icon,
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int amount;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            Text(formatTzs(amount), style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: AppColors.creamDark,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.star, required this.fraction});
  final int star;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Text('$star', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: AppColors.creamDark,
                valueColor: const AlwaysStoppedAnimation(AppColors.amber),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(fraction * 100).round()}%', style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final dynamic review;

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
              // Avatar circle
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  review.name[0],
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
                    // Stars from the review
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

// ── Line chart painter ─────────────────────────────────────────────────

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Y-axis grid lines
    final gridPaint = Paint()
      ..color = AppColors.creamDark
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = h - (i / 4) * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Data points — smooth curve
    final values = [0.15, 0.28, 0.35, 0.42, 0.52, 0.68, 0.88, 1.0, 0.82, 0.72];
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * w;
      final y = h - values[i] * h;
      points.add(Offset(x, y));
    }

    // Gradient fill under curve
    final fillPath = Path()..moveTo(points.first.dx, h);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cpX = (p0.dx + p1.dx) / 2;
      fillPath.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
    }
    fillPath.lineTo(points.last.dx, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.slate.withValues(alpha: 0.18),
          AppColors.slate.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Smooth line
    final linePaint = Paint()
      ..color = AppColors.slate
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cpX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Active dot (at peak — Wednesday index ~4)
    final activeIdx = 4;
    final activePt = points[activeIdx];
    canvas.drawCircle(activePt, 5, Paint()..color = Colors.white);
    canvas.drawCircle(activePt, 5, Paint()..color = AppColors.slate..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(activePt, 2.5, Paint()..color = AppColors.slate);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
