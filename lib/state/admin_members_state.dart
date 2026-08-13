import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ports the source's `aMemberTab` (0 = Clients, 1 = Vendors, 2 = Drivers).
class AdminMembersNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void pickTab(int i) => state = i;
}

final adminMembersProvider = NotifierProvider<AdminMembersNotifier, int>(AdminMembersNotifier.new);
