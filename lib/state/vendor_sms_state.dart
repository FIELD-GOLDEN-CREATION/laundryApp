import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

/// Vendor SMS balance + top-up requests (Beem order/package/promo flow).
class VendorSmsState {
  const VendorSmsState({
    this.remainingPlan = 0,
    this.remainingExtra = 0,
    this.planQuota = 0,
    this.allowed = false,
    this.reason = '',
    this.requests = const [],
    this.isLoading = false,
    this.loaded = false,
  });

  final int remainingPlan;
  final int remainingExtra;
  final int planQuota;

  /// Whether the vendor may currently send (plan toggle + kill-switches).
  final bool allowed;
  final String reason;
  final List<Map<String, dynamic>> requests;
  final bool isLoading;
  final bool loaded;

  int get totalLeft => remainingPlan + remainingExtra;

  VendorSmsState copyWith({
    int? remainingPlan,
    int? remainingExtra,
    int? planQuota,
    bool? allowed,
    String? reason,
    List<Map<String, dynamic>>? requests,
    bool? isLoading,
    bool? loaded,
  }) =>
      VendorSmsState(
        remainingPlan: remainingPlan ?? this.remainingPlan,
        remainingExtra: remainingExtra ?? this.remainingExtra,
        planQuota: planQuota ?? this.planQuota,
        allowed: allowed ?? this.allowed,
        reason: reason ?? this.reason,
        requests: requests ?? this.requests,
        isLoading: isLoading ?? this.isLoading,
        loaded: loaded ?? this.loaded,
      );
}

int _asInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

class VendorSmsNotifier extends Notifier<VendorSmsState> {
  @override
  VendorSmsState build() => const VendorSmsState();

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final balance = await api.getSmsBalance();
      final q = (balance['data'] ?? balance) as Map<String, dynamic>;
      List<Map<String, dynamic>> reqs = state.requests;
      try {
        final r = await api.getSmsRequests();
        final d = r['data'];
        final list = d is Map && d['data'] is List ? d['data'] as List : (d is List ? d : const []);
        reqs = list.whereType<Map<String, dynamic>>().toList();
      } catch (_) {}
      state = state.copyWith(
        remainingPlan: _asInt(q['remaining_plan']),
        remainingExtra: _asInt(q['remaining_extra']),
        planQuota: _asInt(q['plan_quota']),
        allowed: q['allowed'] == true,
        reason: q['reason'] as String? ?? '',
        requests: reqs,
        isLoading: false,
        loaded: true,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, loaded: true);
    }
  }

  /// Returns false when a request is already pending or the API rejects.
  Future<bool> requestMore(int count, {String? note}) async {
    try {
      await api.requestSms(count, note: note);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final vendorSmsProvider = NotifierProvider<VendorSmsNotifier, VendorSmsState>(
  VendorSmsNotifier.new,
);
