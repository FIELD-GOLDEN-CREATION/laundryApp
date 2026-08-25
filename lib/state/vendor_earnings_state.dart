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

/// One month bucket of the earnings chart: payouts (and their amounts)
/// grouped by calendar month.
class MonthBar {
  const MonthBar({required this.label, required this.amountTzs, required this.fraction});
  final String label;
  final double amountTzs;

  /// Height fraction relative to the biggest month (1.0 for the max).
  final double fraction;
}

class VendorEarningsState {
  const VendorEarningsState({
    this.balance = 0,
    this.totalRevenue = 0,
    this.totalPayouts = 0,
    this.pendingPayouts = 0,
    this.totalCommission = 0,
    this.payouts = const [],
    this.reviews = const [],
    this.isLoading = false,
  });

  final double balance;
  final double totalRevenue;
  final double totalPayouts;
  final double pendingPayouts;
  final double totalCommission;
  final List<VendorPayout> payouts;
  final List<ReviewItem> reviews;
  final bool isLoading;

  List<MonthBar> get monthBars {
    final byMonth = <String, double>{};
    for (final p in payouts) {
      final d = p.paidAt;
      if (d == null) continue;
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final key = '${months[d.month - 1]} ${d.year}';
      byMonth[key] = (byMonth[key] ?? 0) + p.amountTzs;
    }
    if (byMonth.isEmpty) return const [];
    // Chronological order, last 6 months at most.
    final entries = byMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final recent = entries.length <= 6 ? entries : entries.sublist(entries.length - 6);
    final peak = recent.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    return [
      for (final e in recent)
        MonthBar(
          label: e.key.split(' ').first,
          amountTzs: e.value,
          fraction: peak == 0 ? 0.0 : (e.value / peak).clamp(0.04, 1.0),
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
        reviews: reviews ?? this.reviews,
        isLoading: isLoading ?? this.isLoading,
      );
}

class VendorEarningsNotifier extends Notifier<VendorEarningsState> {
  @override
  VendorEarningsState build() => const VendorEarningsState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getEarnings();
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
      final rows = await api.getPayouts();
      state = state.copyWith(
        payouts: [
          for (final j in rows)
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
