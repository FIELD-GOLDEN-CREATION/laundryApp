import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification_item.dart';
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
  // The vendor tabs live in a StatefulShellRoute.indexedStack, which keeps
  // this screen mounted and just flips TickerMode off/on when you switch
  // tabs — so `initState` only ever fires once. Watching TickerMode lets us
  // notice each time this tab becomes visible again and bump this key to
  // remount the header chart, replaying its grow-in animation.
  bool? _wasTicking;
  int _chartAnimGen = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(vendorDashboardProvider.notifier).load();
      ref.read(vendorProfileProvider.notifier).loadProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ticking = TickerMode.valuesOf(context).enabled;
    if (ticking && _wasTicking == false) {
      setState(() => _chartAnimGen++);
    }
    _wasTicking = ticking;
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
              _Header(dash: dash, shopTitle: shopTitle, chartAnimGen: _chartAnimGen, onAccount: () => showAccountSheet(context, ref)),

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
                            dash.planStatus.isEmpty ? 'ACTIVE' : dash.planStatus.toUpperCase(),
                            style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.cream, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            dash.planName.isEmpty
                                ? (dash.isLoading ? 'Loading plan…' : 'Basic')
                                : dash.planName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cream),
                          ),
                        ),
                        if (dash.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '${dash.unreadCount}',
                              style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _planDetailLine(dash),
                      style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showChangePlanSheet(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cream,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Change plan'),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Notifications ───────────────────────────────────────
              _SectionHeaderRow(
                title: 'Recent notifications',
                actionLabel: dash.unreadCount > 0 ? '${dash.unreadCount} new' : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: dash.isLoading && dash.notifications.isEmpty
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : dash.notifications.isEmpty
                        ? Text(
                            'You are all caught up.',
                            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                          )
                        : Column(
                            children: [
                              for (var i = 0; i < dash.notifications.length; i++)
                                _VendorNotificationTile(
                                  notif: dash.notifications[i],
                                  isLast: i == dash.notifications.length - 1,
                                  onTap: () => _showNotificationPopup(context, ref, dash.notifications[i].id),
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

String _planDetailLine(VendorDashboardState dash) {
  final parts = <String>[];
  if (dash.planPriceTzs > 0) {
    parts.add('TZS ${dash.planPriceTzs.toStringAsFixed(0)}/${dash.billingPeriod.isEmpty ? 'mo' : dash.billingPeriod}');
  } else {
    parts.add('Free plan');
  }
  parts.add(dash.maxOrders > 0 ? 'max ${dash.maxOrders} orders/mo' : 'unlimited orders');
  return parts.join(' · ');
}

/// Bottom sheet listing all plans with a request-change action.
void _showChangePlanSheet(BuildContext context, WidgetRef ref) {
  final dash = ref.read(vendorDashboardProvider);
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change your plan', style: AppText.serif(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              'Currently on ${dash.planName.isEmpty ? 'your plan' : dash.planName} · ${dash.ordersUsed}/${dash.maxOrders > 0 ? dash.maxOrders : '∞'} orders used',
              style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            if (dash.plans.isEmpty)
              Text(
                'Plans could not be loaded. Check your connection and try again.',
                style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
              )
            else
              for (final p in dash.plans) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.isCurrent ? AppColors.tealMuted : Colors.white,
                    border: Border.all(color: p.isCurrent ? AppColors.teal : AppColors.creamDark),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.displayName, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                              p.priceTzs > 0
                                  ? 'TZS ${p.priceTzs.toStringAsFixed(0)}/mo · ${p.maxOrders > 0 ? 'max ${p.maxOrders} orders' : 'unlimited orders'}'
                                  : 'Free · ${p.maxOrders > 0 ? 'max ${p.maxOrders} orders' : 'unlimited orders'}',
                              style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      if (p.isCurrent)
                        Text('CURRENT', style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.teal))
                      else
                        FilledButton(
                          onPressed: () async {
                            final ok = await ref.read(vendorDashboardProvider.notifier).requestPlanChange(p.id);
                            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok ? 'Request sent for ${p.displayName}.' : 'Request failed — try again.'),
                                ),
                              );
                            }
                          },
                          child: const Text('Request'),
                        ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ),
    ),
  );
}

/// Popup body with the full notification details.
void _showNotificationPopup(BuildContext context, WidgetRef ref, String id) {
  showDialog(
    context: context,
    builder: (dialogContext) => FutureBuilder<Map<String, dynamic>?>(
      future: ref.read(vendorDashboardProvider.notifier).notificationDetail(id),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final order = data?['order'] as Map<String, dynamic>?;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${data?['title'] ?? 'Notification'}', style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else ...[
                  Text(
                    '${data?['body'] ?? ''}',
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate, height: 1.5),
                  ),
                  if (data?['created_at'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${data?['created_at']}',
                      style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ],
                  if (order != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ${order['order_number'] ?? ''}', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${order['status'] ?? ''} · Total: TZS ${order['total_tzs'] ?? 0}',
                            style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
            if (order != null)
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.push('/vendor/order-detail');
                },
                child: const Text('View order'),
              ),
          ],
        );
      },
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.dash, required this.shopTitle, required this.chartAnimGen, required this.onAccount});

  final VendorDashboardState dash;
  final String shopTitle;
  final int chartAnimGen;
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
                      KeyedSubtree(
                        key: ValueKey(chartAnimGen),
                        child: BarChartRow(
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

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({required this.title, this.actionLabel});
  final String title;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 11),
      child: Row(
        children: [
          Expanded(child: Text(title.toUpperCase(), style: AppText.eyebrow())),
          if (actionLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(8)),
              child: Text(actionLabel!, style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.amber)),
            ),
        ],
      ),
    );
  }
}

class _VendorNotificationTile extends StatelessWidget {
  const _VendorNotificationTile({required this.notif, required this.isLast, required this.onTap});
  final NotificationItem notif;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : AppColors.cream)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: notif.isRead ? AppColors.cream : AppColors.tealMuted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(_iconFor(notif.type), size: 16, color: notif.isRead ? AppColors.muted : AppColors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      fontSize: 12.5,
                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!notif.isRead)
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
                const SizedBox(height: 4),
                Text(
                  notif.time,
                  style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'payment':
        return Icons.payments_outlined;
      case 'vendor':
        return Icons.storefront_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
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
