import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverQueueState {
  const DriverQueueState({
    this.tab = 0,
    this.openId = '#LD-2492',
    this.step = const {'#LD-2492': 1},
    this.scanJobId,
    this.checklist = const [true, true, false, false, false],
  });

  final int tab;
  final String? openId;
  final Map<String, int> step;
  final String? scanJobId;
  final List<bool> checklist;

  DriverQueueState copyWith({
    int? tab,
    String? openId,
    bool clearOpenId = false,
    Map<String, int>? step,
    String? scanJobId,
    bool clearScanJobId = false,
    List<bool>? checklist,
  }) => DriverQueueState(
    tab: tab ?? this.tab,
    openId: clearOpenId ? null : (openId ?? this.openId),
    step: step ?? this.step,
    scanJobId: clearScanJobId ? null : (scanJobId ?? this.scanJobId),
    checklist: checklist ?? this.checklist,
  );
}

/// Ports the source's `dQueueTab`/`dOpen`/`dStep`/`dScan`/`dCheck` and the
/// `onStep` handler: stepping past "Verify & collect" (step index 2) opens
/// the scan sheet instead of advancing directly; `confirmScan` jumps
/// straight to step 3 once the sheet's checklist is confirmed. `dCheck` is
/// a single flat list shared across every job's scan — a quirk of the
/// source (it's never reset per-job) ported as-is.
class DriverQueueNotifier extends Notifier<DriverQueueState> {
  @override
  DriverQueueState build() => const DriverQueueState();

  void pickTab(int i) => state = state.copyWith(tab: i);

  void toggleExpand(String id) {
    if (state.openId == id) {
      state = state.copyWith(clearOpenId: true);
    } else {
      state = state.copyWith(openId: id);
    }
  }

  void onStep(String id) {
    final current = state.step[id] ?? 0;
    if (current >= 4) return;
    if (current == 2) {
      state = state.copyWith(scanJobId: id);
      return;
    }
    final next = Map.of(state.step);
    next[id] = current + 1;
    state = state.copyWith(step: next);
  }

  void toggleCheck(int i) {
    final next = List.of(state.checklist);
    next[i] = !next[i];
    state = state.copyWith(checklist: next);
  }

  void confirmScan() {
    final jobId = state.scanJobId;
    if (jobId == null) return;
    final next = Map.of(state.step);
    next[jobId] = 3;
    state = state.copyWith(step: next, clearScanJobId: true);
  }

  void closeScan() => state = state.copyWith(clearScanJobId: true);
}

final driverQueueProvider = NotifierProvider<DriverQueueNotifier, DriverQueueState>(DriverQueueNotifier.new);
