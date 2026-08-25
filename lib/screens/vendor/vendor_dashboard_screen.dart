import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/vendor_dashboard_state.dart';
import '../../state/vendor_profile_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';
import '../../widgets/account_sheet.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/bar_chart_row.dart';
import '../../widgets/stat_tile.dart';

class VendorDashboardScreen extends ConsumerStatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  ConsumerState<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends ConsumerState<VendorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(vendorDashboardProvider.notifier).load();
      ref.read(vendorProfileProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = ref.watch(vendorDashboardProvider);
    final profileTitle = ref.watch(vendorProfileProvider.select((s) => s.shopTitle));
    final shopTitle = profileTitle.isNotEmpty ? profileTitle : dash.shopName;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(dash: dash, shopTitle: shopTitle, onAccount: () => showAccountSheet(context, ref)),

              // ── Order stats row ────────────────────────────────────
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(child: StatTile(value: '${dash.ordersToday}', label: 'Orders today', bg: Colors.white, fg: AppColors.teal)),
                    const SizedBox(width: 8),
                    Expanded(child: StatTile(value: '${dash.activeOrders}', label: 'In progress', bg: AppColors.amberLight, fg: AppColors.amber)),
                    const SizedBox(width: 8),
                    Expanded(child: StatTile(value: '${dash.completedOrders}', label: 'Completed', bg: Colors.white, fg: AppColors.mint)),
                  ],
                ),
              ),

              // ── Needs attention ─────────────────────────────────────
              const _SectionLabel('Needs attention now'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: dash.isLoading && dash.alerts.isEmpty
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : dash.alerts.isEmpty
                        ? Text(
                            'Nothing needs your attention right now.',
                            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < dash.alerts.length; i++) ...[
                                AlertCard(
                                  title: dash.alerts[i].title,
                                  sub: dash.alerts[i].sub,
                                  tag: dash.alerts[i].tag,
                                  accentColor: dash.alerts[i].accentColor,
                                  tagBg: dash.alerts[i].tagBg,
                                  onTap: () => context.push('/vendor/order-detail'),
                                ),
                                if (i != dash.alerts.length - 1) const SizedBox(height: 10),
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
                child: dash.isLoading && dash.weekBars.isEmpty
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : dash.weekBars.isEmpty
                        ? Center(
                            child: Text(
                              'No orders in the last 7 days.',
                              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                            ),
                          )
                        : Row(
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CustomPaint(
                                  painter: _DonutPainter(
                                    segments: [
                                      for (var i = 0; i < dash.weekBars.length; i++)
                                        _DonutSegment(
                                          fraction:
                                              dash.weekTotal == 0 ? 0 : dash.weekBars[i].count / dash.weekTotal,
                                          color: _kDonutColors[i % _kDonutColors.length],
                                        ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${dash.weekTotal}', style: AppText.serif(fontSize: 22, color: AppColors.teal)),
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
                                    for (var i = 0; i < dash.weekBars.length; i++) ...[
                                      if (i != 0) const SizedBox(height: 6),
                                      _DonutLegend(
                                        color: _kDonutColors[i % _kDonutColors.length],
                                        label: dash.weekBars[i].day,
                                        count: '${dash.weekBars[i].count}',
                                      ),
                                    ],
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
                          child: Text(
                            dash.planStatus.isEmpty ? 'PLAN' : dash.planStatus.toUpperCase(),
                            style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.cream, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dash.planName.isEmpty ? 'No active plan' : dash.planName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cream),
                          ),
                        ),
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
                                  value: dash.usageFraction,
                                  minHeight: 6,
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  valueColor: const AlwaysStoppedAnimation(AppColors.mint),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${dash.ordersUsed}/${dash.maxOrders > 0 ? dash.maxOrders : '∞'}',
                          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.mint),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _renewalLabel(dash.periodEnd),
                      style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),

              // ── Notifications ───────────────────────────────────────
              const _SectionLabel('Recent notifications'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: dash.isLoading && dash.alerts.isEmpty
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : dash.alerts.isEmpty
                        ? Text(
                            'You are all caught up.',
                            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < dash.alerts.length; i++)
                                _NotificationTile(
                                  alert: dash.alerts[i],
                                  isLast: i == dash.alerts.length - 1,
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

  String _renewalLabel(String periodEnd) {
    final end = DateTime.tryParse(periodEnd);
    if (end == null) return periodEnd.isEmpty ? 'No renewal date set' : 'Renews $periodEnd';
    final days = end.difference(DateTime.now()).inDays;
    if (days < 0) return 'Period ended ${end.day}/${end.month}';
    return 'Renews in $days day${days == 1 ? '' : 's'}';
  }
}

const _kDonutColors = [AppColors.teal, AppColors.amber, AppColors.mint, AppColors.creamDark, AppColors.slate];

class _Header extends StatelessWidget {
  const _Header({required this.dash, required this.shopTitle, required this.onAccount});

  final VendorDashboardState dash;
  final String shopTitle;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

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
                          Text('${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}', style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.6))),
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
                          Text(formatTzs(dash.revenueTodayTzs), style: AppText.serif(fontSize: 34, color: AppColors.cream)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      BarChartRow(
                        height: 64,
                        gap: 7,
                        barRadius: 4,
                        labelColor: AppColors.cream.withValues(alpha: 0.5),
                        bars: [
                          for (var i = 0; i < dash.weekBars.length; i++)
                            BarDatum(
                              heightFraction: dash.weekBars[i].fraction,
                              color: i == dash.weekBars.length - 1 ? AppColors.amber : Colors.white.withValues(alpha: 0.34),
                              label: dash.weekBars[i].day,
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.alert, required this.isLast});
  final DashboardAlert alert;
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
          Icon(Icons.notifications_active_outlined, size: 16, color: alert.accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.slate),
            ),
          ),
          const SizedBox(width: 8),
          Text(alert.tag, style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted)),
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
