import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review_item.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';
import 'catalog_state.dart' show reviewFromJson;

/// One row of the payout history table.
class VendorPayout {
  const VendorPayout({
    required this.amountTzs,
    required this.method,
    required this.reference,
    required this.status,
    required this.paidAt,
  });

  final double amountTzs;
  final String method;
  final String reference;
  final String status;
  final DateTime? paidAt;

  String get dateLabel {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final d = paidAt;
    if (d == null) return '';
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

/// One row of the per-order money details table.
class EarningLine {
  const EarningLine({
    required this.label,
    required this.sub,
    required this.amountTzs,
    required this.isCredit,
    required this.date,
  });

  final String label;
  final String sub;
  final double amountTzs;
  final bool isCredit;
  final String date;
}

/// One point of the order-amount trend chart.
class TrendPoint {
  const TrendPoint({required this.label, required this.amountTzs});
  final String label;
  final double amountTzs;
}

/// Trend range for the order-amount chart: daily totals for the last
/// 7 days, daily totals for the last 30 days, or monthly totals for the
/// last 12 months.
enum TrendRange { week, month, year }

extension TrendRangeLabel on TrendRange {
  String get label {
    switch (this) {
      case TrendRange.week:
        return 'Week';
      case TrendRange.month:
        return 'Month';
      case TrendRange.year:
        return 'Year';
    }
  }
}

class VendorEarningsState {
  const VendorEarningsState({
    this.balance = 0,
    this.totalRevenue = 0,
    this.totalPayouts = 0,
    this.pendingPayouts = 0,
    this.totalCommission = 0,
    this.payouts = const [],
    this.lines = const [],
    this.reviews = const [],
    this.isLoading = false,
  });

  final double balance;
  final double totalRevenue;
  final double totalPayouts;
  final double pendingPayouts;

  /// Kept for API parity only — the platform takes no commission and the
  /// UI never shows this. Commission rows are filtered out of [orderLines].
  final double totalCommission;
  final List<VendorPayout> payouts;
  final List<EarningLine> lines;
  final List<ReviewItem> reviews;
  final bool isLoading;

  /// Order-payment credits only (commission / adjustment rows excluded).
  /// This is what the order list, the trend chart and the export use.
  List<EarningLine> get orderLines =>
      lines.where((l) => l.isCredit).toList();

  /// Average rating across all reviews (0 when there are none).
  double get avgRating {
    if (reviews.isEmpty) return 0;
    var sum = 0;
    for (final r in reviews) {
      sum += r.stars.length.clamp(1, 5);
    }
    return sum / reviews.length;
  }

  /// Count of reviews per star level, keys 5..1 (always present).
  Map<int, int> get starCounts {
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final s = r.stars.length.clamp(1, 5);
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return counts;
  }

  /// Order-amount trend buckets built from order-payment lines only.
  /// Week → daily totals for the last 7 days, Month → daily totals for the
  /// last 30 days, Year → monthly totals for the last 12 months.
  List<TrendPoint> trendFor(TrendRange range) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (range == TrendRange.year) {
      final totals = List<double>.filled(12, 0);
      for (final l in orderLines) {
        final d = DateTime.tryParse(l.date);
        if (d == null) continue;
        final diff = (now.year - d.year) * 12 + (now.month - d.month);
        if (diff < 0 || diff > 11) continue;
        totals[11 - diff] += l.amountTzs;
      }
      return [
        for (var i = 0; i < 12; i++)
          TrendPoint(
            label: months[DateTime(now.year, now.month - 11 + i).month - 1],
            amountTzs: totals[i],
          ),
      ];
    }

    final days = range == TrendRange.week ? 7 : 30;
    final totals = List<double>.filled(days, 0.0);
    for (final l in orderLines) {
      final d = DateTime.tryParse(l.date);
      if (d == null) continue;
      final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
      if (diff < 0 || diff >= days) continue;
      totals[days - 1 - diff] += l.amountTzs;
    }
    return [
      for (var i = 0; i < days; i++)
        TrendPoint(
          label: days == 7
              ? weekdays[today.subtract(Duration(days: days - 1 - i)).weekday - 1]
              : '${today.subtract(Duration(days: days - 1 - i)).day}',
          amountTzs: totals[i],
        ),
    ];
  }

  VendorEarningsState copyWith({
    double? balance,
    double? totalRevenue,
    double? totalPayouts,
    double? pendingPayouts,
    double? totalCommission,
    List<VendorPayout>? payouts,
    List<EarningLine>? lines,
    List<ReviewItem>? reviews,
    bool? isLoading,
  }) =>
      VendorEarningsState(
        balance: balance ?? this.balance,
        totalRevenue: totalRevenue ?? this.totalRevenue,
        totalPayouts: totalPayouts ?? this.totalPayouts,
        pendingPayouts: pendingPayouts ?? this.pendingPayouts,
        totalCommission: totalCommission ?? this.totalCommission,
        payouts: payouts ?? this.payouts,
        lines: lines ?? this.lines,
        reviews: reviews ?? this.reviews,
        isLoading: isLoading ?? this.isLoading,
      );
}

class VendorEarningsNotifier extends Notifier<VendorEarningsState> {
  Timer? _refreshDebounce;

  @override
  VendorEarningsState build() {
    ref.onDispose(() => _refreshDebounce?.cancel());
    return const VendorEarningsState();
  }

  /// Called by [RealtimeService] for any `order.updated`/`new_order` socket
  /// event on this shop's channel — order status changes (accept/complete)
  /// bust the vendor's finance cache server-side, so balance/payouts/
  /// transactions here can go stale the same way the dashboard's numbers
  /// can. Debounced for the same reason as
  /// [VendorDashboardNotifier.handleRealtimeOrderEvent].
  void handleRealtimeOrderEvent(String action, Map<String, dynamic> order) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), load);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await api.getEarnings();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      state = state.copyWith(
        balance: parseDouble(data['balance']) ?? 0,
        totalRevenue: parseDouble(data['total_revenue']) ?? 0,
        totalPayouts: parseDouble(data['total_payouts']) ?? 0,
        pendingPayouts: parseDouble(data['pending_payouts']) ?? 0,
        totalCommission: parseDouble(data['total_commission']) ?? 0,
        isLoading: false,
      );
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }

    try {
      final data = await api.getPayouts();
      state = state.copyWith(
        payouts: [
          for (final j in data)
            VendorPayout(
              amountTzs: parseDouble(j['amount_tzs']) ?? 0,
              method: j['method'] as String? ?? '',
              reference: j['reference'] as String? ?? '',
              status: j['status'] as String? ?? '',
              paidAt: DateTime.tryParse(j['paid_at'] as String? ?? ''),
            ),
        ],
      );
    } on ApiException {
      // Payout list stays empty; the summary above still renders.
    }

    try {
      final txns = await api.getVendorTransactions();
      state = state.copyWith(
        lines: [
          for (final j in txns)
            EarningLine(
              label: (j['order_number'] as String?)?.isNotEmpty == true
                  ? 'Order ${j['order_number']}'
                  : (j['type'] as String? ?? 'Transaction'),
              sub: [
                if ((j['type'] as String?) != null) j['type'] as String,
                if ((j['method'] as String?)?.isNotEmpty == true) j['method'] as String,
                if ((j['created_at'] as String?)?.isNotEmpty == true)
                  (j['created_at'] as String).substring(0, 10),
              ].join(' · '),
              amountTzs: parseDouble(j['amount_tzs']) ?? 0,
              isCredit: (j['type'] as String?) == 'order_payment',
              date: j['created_at'] as String? ?? '',
            ),
        ],
      );
    } on ApiException {
      // Earnings details stay empty; the summary above still renders.
    }

    // Reviews are best-effort: they need the vendor's shop id, which only
    // the shop endpoint exposes. If it's unavailable, the section is omitted.
    try {
      final shopData = await api.getVendorShop();
      final shop = shopData['data'] as Map<String, dynamic>? ?? shopData;
      final shopId = shop['id']?.toString();
      if (shopId != null && shopId.isNotEmpty && shopId != 'null') {
        final reviews = await api.getShopReviews(shopId);
        state = state.copyWith(reviews: reviews.map(reviewFromJson).toList());
      }
    } on ApiException {
      // Reviews stay empty.
    }
  }
}

final vendorEarningsProvider =
    NotifierProvider<VendorEarningsNotifier, VendorEarningsState>(VendorEarningsNotifier.new);
