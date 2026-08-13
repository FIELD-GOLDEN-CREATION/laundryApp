import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vendor_mock_data.dart';

class VendorOrderDetailState {
  const VendorOrderDetailState({
    this.garment = 0,
    this.damage = kDefaultDamageChecked,
    this.damageNote = '',
    this.tagId = 'MF-2481-A',
    this.step = 2,
  });

  final int garment;
  final List<bool> damage;
  final String damageNote;
  final String tagId;
  final int step;

  VendorOrderDetailState copyWith({int? garment, List<bool>? damage, String? damageNote, String? tagId, int? step}) =>
      VendorOrderDetailState(
        garment: garment ?? this.garment,
        damage: damage ?? this.damage,
        damageNote: damageNote ?? this.damageNote,
        tagId: tagId ?? this.tagId,
        step: step ?? this.step,
      );
}

/// Ports the source's `garment`/`damage[]`/`damageNote`/`tagId`/`vStatus`.
class VendorOrderDetailNotifier extends Notifier<VendorOrderDetailState> {
  @override
  VendorOrderDetailState build() => const VendorOrderDetailState();

  void pickGarment(int i) => state = state.copyWith(garment: i);

  void toggleDamage(int i) {
    final next = List.of(state.damage);
    next[i] = !next[i];
    state = state.copyWith(damage: next);
  }

  void setDamageNote(String v) => state = state.copyWith(damageNote: v);

  void regenTag() {
    const chars = 'ABCDE';
    final rand = Random();
    final id = 'MF-${2400 + rand.nextInt(99)}-${chars[rand.nextInt(chars.length)]}';
    state = state.copyWith(tagId: id);
  }

  void pickStep(int i) => state = state.copyWith(step: i);
}

final vendorOrderDetailProvider = NotifierProvider<VendorOrderDetailNotifier, VendorOrderDetailState>(
  VendorOrderDetailNotifier.new,
);
