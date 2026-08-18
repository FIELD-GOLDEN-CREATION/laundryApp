import 'package:flutter_riverpod/flutter_riverpod.dart';

class VendorLogisticsState {
  const VendorLogisticsState({this.driverPct = 62, this.scanned = false, this.returnDay = 1, this.returnSet = false});

  final int driverPct;
  final bool scanned;
  final int returnDay;
  final bool returnSet;

  VendorLogisticsState copyWith({int? driverPct, bool? scanned, int? returnDay, bool? returnSet}) =>
      VendorLogisticsState(
        driverPct: driverPct ?? this.driverPct,
        scanned: scanned ?? this.scanned,
        returnDay: returnDay ?? this.returnDay,
        returnSet: returnSet ?? this.returnSet,
      );
}

/// Ports the source's `driverPct`/`scanned`/`retDay`/`returnSet`.
class VendorLogisticsNotifier extends Notifier<VendorLogisticsState> {
  @override
  VendorLogisticsState build() => const VendorLogisticsState();

  void moveDriverCloser() =>
      state = state.copyWith(driverPct: state.driverPct >= 96 ? 40 : state.driverPct + 12);

  void toggleScanned() => state = state.copyWith(scanned: !state.scanned);

  void pickReturnDay(int i) => state = state.copyWith(returnDay: i, returnSet: false);

  void scheduleReturn() => state = state.copyWith(returnSet: true);
}

final vendorLogisticsProvider = NotifierProvider<VendorLogisticsNotifier, VendorLogisticsState>(
  VendorLogisticsNotifier.new,
);
