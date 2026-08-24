import 'package:flutter_riverpod/flutter_riverpod.dart';

class VendorOrdersState {
  const VendorOrdersState({
    this.tab = 0,
    this.accepted = const {},
    this.deliveryFees = const {},
  });

  final int tab;
  final Map<String, bool> accepted;
  final Map<String, int> deliveryFees;

  VendorOrdersState copyWith({
    int? tab,
    Map<String, bool>? accepted,
    Map<String, int>? deliveryFees,
  }) =>
      VendorOrdersState(
        tab: tab ?? this.tab,
        accepted: accepted ?? this.accepted,
        deliveryFees: deliveryFees ?? this.deliveryFees,
      );
}

class VendorOrdersNotifier extends Notifier<VendorOrdersState> {
  @override
  VendorOrdersState build() => const VendorOrdersState();

  void pickTab(int i) => state = state.copyWith(tab: i);

  void acceptOrder(String orderId, {int deliveryFeeTzs = 0}) {
    final nextAccepted = Map.of(state.accepted);
    final nextFees = Map.of(state.deliveryFees);
    nextAccepted[orderId] = true;
    if (deliveryFeeTzs > 0) {
      nextFees[orderId] = deliveryFeeTzs;
    }
    state = state.copyWith(accepted: nextAccepted, deliveryFees: nextFees);
  }

  void rejectOrder(String orderId) {
    final nextAccepted = Map.of(state.accepted);
    final nextFees = Map.of(state.deliveryFees);
    nextAccepted.remove(orderId);
    nextFees.remove(orderId);
    state = state.copyWith(accepted: nextAccepted, deliveryFees: nextFees);
  }
}

final vendorOrdersProvider =
    NotifierProvider<VendorOrdersNotifier, VendorOrdersState>(VendorOrdersNotifier.new);
