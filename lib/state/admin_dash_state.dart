import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ports the source's `aMapSeed`/`shuffleMap`.
class AdminDashNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void shuffleMap() => state = (state + 1) % 4;
}

final adminDashProvider = NotifierProvider<AdminDashNotifier, int>(AdminDashNotifier.new);
