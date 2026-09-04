import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../utils/num_helper.dart';
import '../theme/colors.dart';

/// One "needs attention" row from GET /vendor/dashboard's `alerts`.
class DashboardAlert {
  const DashboardAlert({
    required this.title,
    required this.sub,
    required this.tag,
    this.isWarning = false,
  });

  final String title;
  final String sub;
  final String tag;
  final bool isWarning;

  Color get accentColor => isWarning ? AppColors.amber : AppColors.teal;
  Color get tagBg => isWarning ? AppColors.amberLight : AppColors.tealMuted;
}

/// One normalized bar of the trailing-7-days order chart.
class WeekBar {
  const WeekBar({required this.day, required this.count, required this.fraction});
  final String day;
  final int count;

  /// Height fraction relative to the busiest day (1.0 for the max).
  final double fraction;
}

class VendorDashboardState {
  const VendorDashboardState({
    this.shopName = '',
    this.ordersToday = 0,
    this.revenueTodayTzs = 0,
    this.activeOrders = 0,
    this.completedOrders = 0,
    this.totalCustomers = 0,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.weekBars = const [],
    this.alerts = const [],
    this.planName = '',
    this.planStatus = '',
    this.ordersUsed = 0,
    this.maxOrders = 0,
    this.periodEnd = '',
    this.isLoading = false,
  });

  final String shopName;
  final int ordersToday;
  final int revenueTodayTzs;
  final int activeOrders;
  final int completedOrders;
  final int totalCustomers;
  final double ratingAvg;
  final int ratingCount;
  final List<WeekBar> weekBars;
  final List<DashboardAlert> alerts;

  final String planName;
  final String planStatus;
  final int ordersUsed;
  final int maxOrders;
  final String periodEnd;

  final bool isLoading;

  /// 0..1 subscription usage for the plan progress bar.
  double get usageFraction =>
      maxOrders > 0 ? (ordersUsed / maxOrders).clamp(0.0, 1.0) : 0.0;

  int get weekTotal =>
      weekBars.fold(0, (sum, bar) => sum + bar.count);

  VendorDashboardState copyWith({
    String? shopName,
    int? ordersToday,
    int? revenueTodayTzs,
    int? activeOrders,
    int? completedOrders,
    int? totalCustomers,
    double? ratingAvg,
    int? ratingCount,
    List<WeekBar>? weekBars,
    List<DashboardAlert>? alerts,
    String? planName,
    String? planStatus,
    int? ordersUsed,
    int? maxOrders,
    String? periodEnd,
    bool? isLoading,
  }) =>
      VendorDashboardState(
        shopName: shopName ?? this.shopName,
        ordersToday: ordersToday ?? this.ordersToday,
        revenueTodayTzs: revenueTodayTzs ?? this.revenueTodayTzs,
        activeOrders: activeOrders ?? this.activeOrders,
        completedOrders: completedOrders ?? this.completedOrders,
        totalCustomers: totalCustomers ?? this.totalCustomers,
        ratingAvg: ratingAvg ?? this.ratingAvg,
        ratingCount: ratingCount ?? this.ratingCount,
        weekBars: weekBars ?? this.weekBars,
        alerts: alerts ?? this.alerts,
        planName: planName ?? this.planName,
        planStatus: planStatus ?? this.planStatus,
        ordersUsed: ordersUsed ?? this.ordersUsed,
        maxOrders: maxOrders ?? this.maxOrders,
        periodEnd: periodEnd ?? this.periodEnd,
        isLoading: isLoading ?? this.isLoading,
      );
}

class VendorDashboardNotifier extends Notifier<VendorDashboardState> {
  @override
  VendorDashboardState build() => const VendorDashboardState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await api.getVendorDashboard();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final shop = data['shop'] as Map<String, dynamic>? ?? {};
      final sub = data['subscription'] as Map<String, dynamic>? ?? {};

      state = VendorDashboardState(
        shopName: shop['name'] as String? ?? '',
        ordersToday: parseInt(data['orders_today']) ?? 0,
        revenueTodayTzs: parseInt(data['revenue_today']) ?? 0,
        activeOrders: parseInt(data['active_orders']) ?? 0,
        completedOrders: parseInt(data['completed_orders']) ?? 0,
        totalCustomers: parseInt(data['total_customers']) ?? 0,
        ratingAvg: parseDouble(data['rating_avg']) ?? 0,
        ratingCount: parseInt(data['rating_count']) ?? 0,
        weekBars: _weekBars(data['week_bars'] as List?),
        alerts: _alerts(data['alerts'] as List?),
        planName: sub['plan_name'] as String? ?? '',
        planStatus: sub['status'] as String? ?? '',
        ordersUsed: parseInt(sub['orders_used']) ?? 0,
        maxOrders: parseInt(sub['max_orders_per_month']) ?? 0,
        periodEnd: sub['current_period_end'] as String? ?? '',
      );
    } on ApiException {
      // Keep prior state — a stale dashboard beats an empty one.
      state = state.copyWith(isLoading: false);
    }
  }

  List<WeekBar> _weekBars(List? raw) {
    final rows = (raw ?? []).whereType<Map<String, dynamic>>().toList();
    if (rows.isEmpty) return const [];
    final counts = [
      for (final r in rows) parseInt(r['count']) ?? 0,
    ];
    final peak = counts.fold<int>(0, (m, c) => c > m ? c : m);
    return [
      for (var i = 0; i < rows.length; i++)
        WeekBar(
          day: rows[i]['day'] as String? ?? '',
          count: counts[i],
          fraction: peak == 0 ? 0.0 : (counts[i] / peak).clamp(0.04, 1.0),
        ),
    ];
  }

  List<DashboardAlert> _alerts(List? raw) {
    return [
      for (final j in (raw ?? []).whereType<Map<String, dynamic>>())
        DashboardAlert(
          title: j['title'] as String? ?? '',
          sub: j['sub'] as String? ?? '',
          tag: j['tag'] as String? ?? '',
          isWarning: (j['type'] as String?) == 'warning',
        ),
    ];
  }
}

final vendorDashboardProvider =
    NotifierProvider<VendorDashboardNotifier, VendorDashboardState>(VendorDashboardNotifier.new);
