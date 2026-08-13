import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverDashState {
  const DriverDashState({this.online = true, this.secs = 742});

  final bool online;
  final int secs;

  DriverDashState copyWith({bool? online, int? secs}) =>
      DriverDashState(online: online ?? this.online, secs: secs ?? this.secs);
}

/// Ports the source's `dOnline`/`dSecs` + the root component's
/// `componentDidMount` interval that ticks `dSecs` down once a second while
/// `role==='driver'`. Scoped to this provider's lifetime rather than the
/// whole app, since it's only ever displayed on the Shift dashboard.
class DriverDashNotifier extends Notifier<DriverDashState> {
  Timer? _timer;

  @override
  DriverDashState build() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secs > 0) state = state.copyWith(secs: state.secs - 1);
    });
    ref.onDispose(() => _timer?.cancel());
    return const DriverDashState();
  }

  void toggleOnline() => state = state.copyWith(online: !state.online);
}

final driverDashProvider = NotifierProvider<DriverDashNotifier, DriverDashState>(DriverDashNotifier.new);
