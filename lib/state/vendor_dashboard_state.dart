import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_item.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';
import '../theme/colors.dart';
import 'notifications_state.dart' show notificationFromJson;

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

/// One available subscription plan (for the change-plan sheet).
class PlanOption {
  const PlanOption({
    required this.id,
    required this.name,
    required this.displayName,
    required this.priceTzs,
    required this.maxOrders,
    required this.isCurrent,
  });

  final String id;
  final String name;
  final String displayName;
  final double priceTzs;
  final int maxOrders;
  final bool isCurrent;
}

class VendorDashboardState {
  const VendorDashboardState({
    this.shopId = 0,
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
    this.notifications = const [],
    this.unreadCount = 0,
    this.planName = '',
    this.planSlug = '',
    this.planStatus = '',
    this.planPriceTzs = 0,
    this.billingPeriod = '',
    this.ordersUsed = 0,
    this.maxOrders = 0,
    this.periodStart = '',
    this.periodEnd = '',
    this.plans = const [],
    this.isLoading = false,
  });

  /// Backend `shops.id` — 0 until the first dashboard load resolves it.
  /// Needed client-side for the realtime service's per-shop private channel
  /// (`private-vendor-shop.{id}`).
  final int shopId;
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
  final List<NotificationItem> notifications;
  final int unreadCount;

  final String planName;
  final String planSlug;
  final String planStatus;
  final double planPriceTzs;
  final String billingPeriod;
  final int ordersUsed;
  final int maxOrders;
  final String periodStart;
  final String periodEnd;
  final List<PlanOption> plans;

  final bool isLoading;

  /// Never show "No active plan": while loading keep the previous name,
  /// and after load the backend always provisions a plan.
  bool get hasPlan => planName.isNotEmpty;

  /// 0..1 subscription usage for the plan progress bar.
  double get usageFraction =>
      maxOrders > 0 ? (ordersUsed / maxOrders).clamp(0.0, 1.0) : 0.0;

  int get weekTotal =>
      weekBars.fold(0, (sum, bar) => sum + bar.count);

  VendorDashboardState copyWith({
    int? shopId,
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
    List<NotificationItem>? notifications,
    int? unreadCount,
    String? planName,
    String? planSlug,
    String? planStatus,
    double? planPriceTzs,
    String? billingPeriod,
    int? ordersUsed,
    int? maxOrders,
    String? periodStart,
    String? periodEnd,
    List<PlanOption>? plans,
    bool? isLoading,
  }) =>
      VendorDashboardState(
        shopId: shopId ?? this.shopId,
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
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        planName: planName ?? this.planName,
        planSlug: planSlug ?? this.planSlug,
        planStatus: planStatus ?? this.planStatus,
        planPriceTzs: planPriceTzs ?? this.planPriceTzs,
        billingPeriod: billingPeriod ?? this.billingPeriod,
        ordersUsed: ordersUsed ?? this.ordersUsed,
        maxOrders: maxOrders ?? this.maxOrders,
        periodStart: periodStart ?? this.periodStart,
        periodEnd: periodEnd ?? this.periodEnd,
        plans: plans ?? this.plans,
        isLoading: isLoading ?? this.isLoading,
      );
}

class VendorDashboardNotifier extends Notifier<VendorDashboardState> {
  Timer? _refreshDebounce;

  @override
  VendorDashboardState build() {
    ref.onDispose(() => _refreshDebounce?.cancel());
    return const VendorDashboardState();
  }

  /// Called by [RealtimeService] whenever a `order.updated` (or `new_order`)
  /// socket event lands on this shop's channel. Deliberately doesn't try to
  /// patch the dashboard's aggregate numbers (revenue, week bars, alerts)
  /// from the small event payload — those stay sourced from one place
  /// (`load()`/`VendorDashboardController`) so they can't drift out of sync.
  /// Debounced so a burst of events (e.g. bulk-complete touching several
  /// orders) triggers one refetch, not one per event.
  void handleRealtimeOrderEvent(String action, Map<String, dynamic> order) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), load);
  }

  /// Called by [RealtimeService] for a `notification.created` socket event.
  /// Unlike order events, a notification's payload is already everything
  /// the "Recent notifications" list needs, so this patches state directly
  /// for an instant bump instead of waiting on a refetch.
  void handleRealtimeNotification(Map<String, dynamic> json) {
    final notif = notificationFromJson(json);
    if (state.notifications.any((n) => n.id == notif.id)) return;
    state = state.copyWith(
      notifications: [notif, ...state.notifications].take(10).toList(),
      unreadCount: notif.isRead ? state.unreadCount : state.unreadCount + 1,
    );
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await api.getVendorDashboard();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final shop = data['shop'] as Map<String, dynamic>? ?? {};
      final sub = data['subscription'] as Map<String, dynamic>? ?? {};
      final notifs = (data['recent_notifications'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(notificationFromJson)
              .toList() ??
          const [];

      state = state.copyWith(
        shopId: parseInt(shop['id']) ?? state.shopId,
        shopName: shop['name'] as String? ?? state.shopName,
        ordersToday: parseInt(data['orders_today']) ?? 0,
        revenueTodayTzs: parseInt(data['revenue_today']) ?? 0,
        activeOrders: parseInt(data['active_orders']) ?? 0,
        completedOrders: parseInt(data['completed_orders']) ?? 0,
        totalCustomers: parseInt(data['total_customers']) ?? 0,
        ratingAvg: parseDouble(data['rating_avg']) ?? 0,
        ratingCount: parseInt(data['rating_count']) ?? 0,
        weekBars: _weekBars(data['week_bars'] as List?),
        alerts: _alerts(data['alerts'] as List?),
        notifications: notifs,
        unreadCount: parseInt(data['unread_count']) ?? 0,
        planName: (sub['plan_name'] as String?)?.isNotEmpty == true
            ? sub['plan_name'] as String
            : state.planName,
        planSlug: sub['plan_slug'] as String? ?? state.planSlug,
        planStatus: sub['status'] as String? ?? state.planStatus,
        planPriceTzs: parseDouble(sub['price_tzs']) ?? state.planPriceTzs,
        billingPeriod: sub['billing_period'] as String? ?? state.billingPeriod,
        ordersUsed: parseInt(sub['orders_used']) ?? 0,
        maxOrders: parseInt(sub['max_orders_per_month']) ?? 0,
        periodStart: sub['current_period_start'] as String? ?? state.periodStart,
        periodEnd: sub['current_period_end'] as String? ?? state.periodEnd,
        isLoading: false,
      );
    } on ApiException {
      // Keep prior state — a stale dashboard beats an empty one.
      state = state.copyWith(isLoading: false);
    }

    // Plans + full subscription details for the change-plan sheet.
    try {
      final subRes = await api.getVendorSubscription();
      final current = subRes['data'] as Map<String, dynamic>?;
      final plans = (subRes['plans'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
          ((await api.getSubscriptionPlans()).whereType<Map<String, dynamic>>().toList());
      final currentId = '${current?['plan_id'] ?? current?['plan']?['id'] ?? ''}';
      final sub = current ?? {};
      state = state.copyWith(
        plans: [
          for (final p in plans)
            PlanOption(
              id: '${p['id']}',
              name: p['name'] as String? ?? '',
              displayName: p['display_name'] as String? ?? p['name'] as String? ?? '',
              priceTzs: parseDouble(p['price_tzs']) ?? 0,
              maxOrders: parseInt(p['max_orders_per_month']) ?? 0,
              isCurrent: '${p['id']}' == currentId,
            ),
        ],
        planName: (sub['plan'] as Map?)?['display_name'] as String? ??
            (sub['plan'] as Map?)?['name'] as String? ??
            state.planName,
      );
    } on ApiException {
      // Plans sheet stays empty; dashboard still renders.
    }
  }

  Future<bool> requestPlanChange(String planId, {String? note}) async {
    try {
      await api.requestPlanChange(planId, note: note);
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<Map<String, dynamic>?> notificationDetail(String id) async {
    try {
      final res = await api.getVendorNotificationDetail(id);
      final payload = res['data'] as Map<String, dynamic>?;
      if (payload != null) {
        final wasUnread = state.notifications.any((n) => n.id == id && !n.isRead);
        state = state.copyWith(
          notifications: [
            for (final n in state.notifications)
              n.id == id ? n.copyWith(isRead: true) : n,
          ],
          unreadCount: wasUnread && state.unreadCount > 0 ? state.unreadCount - 1 : state.unreadCount,
        );
      }
      return payload;
    } on ApiException {
      return null;
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
