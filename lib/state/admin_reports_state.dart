import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminReportsState {
  const AdminReportsState({this.agent = 0, this.period = 1, this.exported = false});

  final int agent;
  final int period;
  final bool exported;

  AdminReportsState copyWith({int? agent, int? period, bool? exported}) =>
      AdminReportsState(agent: agent ?? this.agent, period: period ?? this.period, exported: exported ?? this.exported);
}

/// Ports the source's `aAgent`/`aPeriod`/`exported`.
class AdminReportsNotifier extends Notifier<AdminReportsState> {
  @override
  AdminReportsState build() => const AdminReportsState();

  void pickAgent(int i) => state = state.copyWith(agent: i, exported: false);
  void pickPeriod(int i) => state = state.copyWith(period: i, exported: false);
  void exportReport() => state = state.copyWith(exported: true);
}

final adminReportsProvider = NotifierProvider<AdminReportsNotifier, AdminReportsState>(AdminReportsNotifier.new);
