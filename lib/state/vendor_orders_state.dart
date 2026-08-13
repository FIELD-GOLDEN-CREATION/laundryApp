import 'package:flutter_riverpod/flutter_riverpod.dart';

class VendorOrdersState {
  const VendorOrdersState({this.tab = 0, this.accepted = const {}});

  final int tab;
  final Map<String, bool> accepted;

  VendorOrdersState copyWith({int? tab, Map<String, bool>? accepted}) =>
      VendorOrdersState(tab: tab ?? this.tab, accepted: accepted ?? this.accepted);
}

/// Ports the source's `vOrderTab`/`accepted{}`.
class VendorOrdersNotifier extends Notifier<VendorOrdersState> {
  @override
  VendorOrdersState build() => const VendorOrdersState();

  void pickTab(int i) => state = state.copyWith(tab: i);

  void toggleAccepted(String orderId) {
    final next = Map.of(state.accepted);
    next[orderId] = !(next[orderId] ?? false);
    state = state.copyWith(accepted: next);
  }
}

final vendorOrdersProvider = NotifierProvider<VendorOrdersNotifier, VendorOrdersState>(VendorOrdersNotifier.new);
