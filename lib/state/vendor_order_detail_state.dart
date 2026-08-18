import 'package:flutter_riverpod/flutter_riverpod.dart';

class VendorOrderDetailState {
  const VendorOrderDetailState({this.tagId = 'MF-2481-A', this.step = 1});

  final String tagId;
  final int step;

  VendorOrderDetailState copyWith({String? tagId, int? step}) =>
      VendorOrderDetailState(tagId: tagId ?? this.tagId, step: step ?? this.step);
}

/// Ports the source's `tagId`/`vStatus`.
class VendorOrderDetailNotifier extends Notifier<VendorOrderDetailState> {
  @override
  VendorOrderDetailState build() => const VendorOrderDetailState();

  void pickStep(int i) => state = state.copyWith(step: i);
}

final vendorOrderDetailProvider = NotifierProvider<VendorOrderDetailNotifier, VendorOrderDetailState>(
  VendorOrderDetailNotifier.new,
);
