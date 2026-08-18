import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vendor_order_decision.dart';

class VendorOrdersState {
  const VendorOrdersState({this.tab = 0, this.acceptances = const {}, this.rejections = const {}});

  final int tab;

  /// Incoming orders the vendor has accepted, keyed by order id.
  final Map<String, VendorOrderAcceptance> acceptances;

  /// Incoming orders the vendor has rejected, keyed by order id, with the
  /// reason the vendor entered.
  final Map<String, String> rejections;

  VendorOrdersState copyWith({
    int? tab,
    Map<String, VendorOrderAcceptance>? acceptances,
    Map<String, String>? rejections,
  }) => VendorOrdersState(
    tab: tab ?? this.tab,
    acceptances: acceptances ?? this.acceptances,
    rejections: rejections ?? this.rejections,
  );
}

/// Tracks the vendor's accept/reject decision for each incoming order.
/// Replaces the old single `accepted{}` toggle now that accepting requires
/// setting a delivery fee and payment options, and rejecting requires a
/// reason — both captured via the sheets in
/// `widgets/vendor_accept_order_sheet.dart` and
/// `widgets/vendor_reject_order_sheet.dart`.
class VendorOrdersNotifier extends Notifier<VendorOrdersState> {
  @override
  VendorOrdersState build() => const VendorOrdersState();

  void pickTab(int i) => state = state.copyWith(tab: i);

  void acceptOrder(String orderId, VendorOrderAcceptance acceptance) {
    final acceptances = Map.of(state.acceptances)..[orderId] = acceptance;
    final rejections = Map.of(state.rejections)..remove(orderId);
    state = state.copyWith(acceptances: acceptances, rejections: rejections);
  }

  void rejectOrder(String orderId, String reason) {
    final rejections = Map.of(state.rejections)..[orderId] = reason;
    final acceptances = Map.of(state.acceptances)..remove(orderId);
    state = state.copyWith(acceptances: acceptances, rejections: rejections);
  }
}

final vendorOrdersProvider = NotifierProvider<VendorOrdersNotifier, VendorOrdersState>(VendorOrdersNotifier.new);
