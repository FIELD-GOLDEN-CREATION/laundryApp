import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/vendor_mock_data.dart';
import '../../state/vendor_profile_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/account_sheet.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/bar_chart_row.dart';
import '../../widgets/stat_tile.dart';

/// Vendor-side mock notification data.
const _kVendorNotifications = [
  _VendorNotif(icon: Icons.receipt_long_rounded, title: 'New order #LD-2492', sub: 'Nina Alvarez · 6 items · Express', time: '4 min ago', color: AppColors.teal),
  _VendorNotif(icon: Icons.local_shipping_outlined, title: 'Driver assigned to #LD-2478', sub: 'Grace Bello · 9 items ready for delivery', time: '18 min ago', color: AppColors.teal),
  _VendorNotif(icon: Icons.star_rounded, title: 'New 5-star review', sub: 'Amara R. — "They flagged a stain before washing"', time: '1 hour ago', color: AppColors.amber),
  _VendorNotif(icon: Icons.payments_outlined, title: 'Weekly payout processed', sub: 'TZS 7,644,260 deposited to •••• 8821', time: 'Yesterday', color: AppColors.teal),
  _VendorNotif(icon: Icons.warning_amber_rounded, title: 'Express deadline approaching', sub: '#LD-2486 · Wedding dress · 6h remaining', time: '2 hours ago', color: AppColors.amber),
];

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopTitle = ref.watch(vendorProfileProvider.select((s) => s.shopTitle));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(shopTitle: shopTitle, onAccount: () => showAccountSheet(context, ref)),

              // ── Order stats row ────────────────────────────────────
              const SizedBox(height: 18),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(child: StatTile(value: '12', label: 'Accepted', bg: Colors.white, fg: AppColors.teal)),
                    SizedBox(width: 8),
                    Expanded(child: StatTile(value: '7', label: 'Pending', bg: AppColors.amberLight, fg: AppColors.amber)),
                    SizedBox(width: 8),
                    Expanded(child: StatTile(value: '2', label: 'Ready', bg: Colors.white, fg: AppColors.mint)),
                  ],
                ),
              ),

              // ── Needs attention ─────────────────────────────────────
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

              // ── Order trend donut ──────────────────────────────────
              const _SectionLabel('Order trend — last 7 days'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.creamDark),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          segments: const [
                            _DonutSegment(fraction: 0.39, color: AppColors.teal),
                            _DonutSegment(fraction: 0.26, color: AppColors.amber),
                            _DonutSegment(fraction: 0.22, color: AppColors.mint),
                            _DonutSegment(fraction: 0.13, color: AppColors.creamDark),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('23', style: AppText.serif(fontSize: 22, color: AppColors.teal)),
                              Text('orders', style: AppText.sans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(6)),
                                child: Text('+18%', style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.teal)),
                              ),
                              const SizedBox(width: 6),
                              Text('vs last week', style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _DonutLegend(color: AppColors.teal, label: 'Accepted', count: '9'),
                          const SizedBox(height: 6),
                          _DonutLegend(color: AppColors.amber, label: 'Pending', count: '6'),
                          const SizedBox(height: 6),
                          _DonutLegend(color: AppColors.mint, label: 'Ready', count: '5'),
                          const SizedBox(height: 6),
                          _DonutLegend(color: AppColors.creamDark, label: 'Cancelled', count: '3'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Subscription plan ───────────────────────────────────
              const _SectionLabel('Your subscription'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.teal, Color(0xFF0F3D3A)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(8)),
                          child: Text('PRO', style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.cream, letterSpacing: 1)),
                        ),
                        const SizedBox(width: 10),
                        Text('Pro Plan', style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cream)),
                        const Spacer(),
                        Text('TZS 75,000/mo', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.cream.withValues(alpha: 0.7))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _PlanFeature(label: 'Unlimited orders', icon: Icons.check_rounded),
                        const SizedBox(width: 16),
                        _PlanFeature(label: '5 packages', icon: Icons.check_rounded),
                        const SizedBox(width: 16),
                        _PlanFeature(label: 'Priority support', icon: Icons.check_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Usage this month', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.6))),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: 0.68,
                                  minHeight: 6,
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  valueColor: const AlwaysStoppedAnimation(AppColors.mint),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('68%', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.mint)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Renews in 12 days', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.5))),
                  ],
                ),
              ),

              // ── Recent notifications ────────────────────────────────
              const _SectionLabel('Recent notifications'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    for (var i = 0; i < _kVendorNotifications.length; i++)
                      _NotificationTile(
                        notif: _kVendorNotifications[i],
                        isLast: i == _kVendorNotifications.length - 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.shopTitle, required this.onAccount});

  final String shopTitle;
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WEDNESDAY, 12 AUG', style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.6))),
                          const SizedBox(height: 6),
                          Text(
                            shopTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.serif(fontSize: 25, color: AppColors.cream),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
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
                      const SizedBox(height: 16),
                      BarChartRow(
                        height: 64,
                        gap: 7,
                        barRadius: 4,
                        labelColor: AppColors.cream.withValues(alpha: 0.5),
                        bars: [
                          for (var i = 0; i < kWeekBarFractions.length; i++)
                            BarDatum(
                              heightFraction: kWeekBarFractions[i],
                              color: i == 6 ? AppColors.amber : Colors.white.withValues(alpha: 0.34),
                              label: kWeekBarLabels[i],
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

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.mint),
        const SizedBox(width: 4),
        Text(label, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.cream.withValues(alpha: 0.85))),
      ],
    );
  }
}

class _VendorNotif {
  const _VendorNotif({required this.icon, required this.title, required this.sub, required this.time, required this.color});
  final IconData icon;
  final String title;
  final String sub;
  final String time;
  final Color color;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notif, required this.isLast});
  final _VendorNotif notif;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : AppColors.cream)),
      ),
      child: Row(
        children: [
          Icon(notif.icon, size: 16, color: notif.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notif.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.slate),
            ),
          ),
          const SizedBox(width: 8),
          Text(notif.time, style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted)),
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

class _DonutSegment {
  const _DonutSegment({required this.fraction, required this.color});
  final double fraction;
  final Color color;
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments});
  final List<_DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    double startAngle = -1.5708;
    for (final seg in segments) {
      final sweepAngle = seg.fraction * 6.2832;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => false;
}

class _DonutLegend extends StatelessWidget {
  const _DonutLegend({required this.color, required this.label, required this.count});
  final Color color;
  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted))),
        Text(count, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.slate)),
      ],
    );
  }
}
