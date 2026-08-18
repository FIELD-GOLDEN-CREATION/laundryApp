import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverProfileState {
  const DriverProfileState({this.locReqDone = false, this.togglesOn = const [false, false]});

  final bool locReqDone;
  final List<bool> togglesOn;

  DriverProfileState copyWith({bool? locReqDone, List<bool>? togglesOn}) =>
      DriverProfileState(locReqDone: locReqDone ?? this.locReqDone, togglesOn: togglesOn ?? this.togglesOn);
}

/// Ports the source's `locReqDone`/`dTogglesOn`.
class DriverProfileNotifier extends Notifier<DriverProfileState> {
  @override
  DriverProfileState build() => const DriverProfileState();

  void requestLoc() => state = state.copyWith(locReqDone: true);

  void toggleAppControl(int i) {
    final next = List.of(state.togglesOn);
    next[i] = !next[i];
    state = state.copyWith(togglesOn: next);
  }
}

final driverProfileProvider = NotifierProvider<DriverProfileNotifier, DriverProfileState>(DriverProfileNotifier.new);
