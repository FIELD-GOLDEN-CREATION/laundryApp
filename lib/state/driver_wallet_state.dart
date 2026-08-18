import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ports the source's `payoutDone`.
class DriverWalletNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void requestPayout() => state = true;
}

final driverWalletProvider = NotifierProvider<DriverWalletNotifier, bool>(DriverWalletNotifier.new);
