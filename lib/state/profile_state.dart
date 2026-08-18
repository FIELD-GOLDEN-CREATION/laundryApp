import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/address.dart';

class ProfileState {
  const ProfileState({required this.prefsOn, required this.addresses, this.fav = false, this.name = 'Amara Reed', this.phone = '+255 712 345 678', this.photoLabel = 'You'});

  final List<bool> prefsOn;
  final List<Address> addresses;
  final bool fav;
  final String name;
  final String phone;
  final String photoLabel;

  ProfileState copyWith({List<bool>? prefsOn, List<Address>? addresses, bool? fav, String? name, String? phone, String? photoLabel}) => ProfileState(
    prefsOn: prefsOn ?? this.prefsOn,
    addresses: addresses ?? this.addresses,
    fav: fav ?? this.fav,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    photoLabel: photoLabel ?? this.photoLabel,
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

  void updateDetails({required String name, required String phone, String? photoLabel}) => state = state.copyWith(name: name, phone: phone, photoLabel: photoLabel);

  void updateAddressLine(int i, String line) {
    final next = List.of(state.addresses);
    next[i] = Address(label: next[i].label, line: line);
    state = state.copyWith(addresses: next);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
