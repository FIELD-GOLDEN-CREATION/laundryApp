import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/address.dart';

class ProfileState {
  const ProfileState({required this.prefsOn, required this.addresses, this.fav = false});

  final List<bool> prefsOn;
  final List<Address> addresses;
  final bool fav;

  ProfileState copyWith({List<bool>? prefsOn, List<Address>? addresses, bool? fav}) => ProfileState(
    prefsOn: prefsOn ?? this.prefsOn,
    addresses: addresses ?? this.addresses,
    fav: fav ?? this.fav,
  );
}

/// Ports the source's `prefsOn` toggles + the shop-detail `fav` flag.
class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => ProfileState(prefsOn: List.of(kDefaultPrefsOn), addresses: List.of(kAddresses));

  void togglePref(int i) {
    final next = List.of(state.prefsOn);
    next[i] = !next[i];
    state = state.copyWith(prefsOn: next);
  }

  void toggleFav() => state = state.copyWith(fav: !state.fav);

  void updateAddressLine(int i, String line) {
    final next = List.of(state.addresses);
    next[i] = Address(label: next[i].label, line: line);
    state = state.copyWith(addresses: next);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
