import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../utils/num_helper.dart';

/// Public platform-wide aggregates for marketing surfaces (e.g. the "become
/// a vendor" banner) — real counts from GET /platform/stats.
class PlatformStats {
  const PlatformStats({
    required this.vendorCount,
    required this.avgRating,
    required this.monthlyEarningsTzs,
  });

  final int vendorCount;

  /// Null when no active vendor has a rating yet.
  final double? avgRating;

  final int monthlyEarningsTzs;
}

final platformStatsProvider = FutureProvider<PlatformStats>((ref) async {
  final data = await api.getPlatformStats();
  final body = (data['data'] ?? data) as Map<String, dynamic>;
  return PlatformStats(
    vendorCount: parseInt(body['vendor_count']) ?? 0,
    avgRating: parseDouble(body['avg_rating']),
    monthlyEarningsTzs: parseInt(body['monthly_earnings_tzs']) ?? 0,
  );
});
