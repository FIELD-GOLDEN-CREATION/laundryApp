import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ports the source's `aTransport`.
class AdminDriverDetailNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void pickTransport(int i) => state = i;
}

final adminDriverDetailProvider = NotifierProvider<AdminDriverDetailNotifier, int>(AdminDriverDetailNotifier.new);
