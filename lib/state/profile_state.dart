import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address.dart';
import '../services/api_service.dart';

class ProfileState {
  const ProfileState({
    required this.addresses,
    this.fav = false,
    this.name = '',
    this.phone = '',
    this.photoLabel = 'You',
    this.photoUrl,
    this.isLoading = false,
  });

  final List<Address> addresses;
  final bool fav;
  final String name;
  final String phone;
  final String photoLabel;
  final String? photoUrl;
  final bool isLoading;

  ProfileState copyWith({
    List<Address>? addresses,
    bool? fav,
    String? name,
    String? phone,
    String? photoLabel,
    String? photoUrl,
    bool? isLoading,
  }) =>
      ProfileState(
        addresses: addresses ?? this.addresses,
        fav: fav ?? this.fav,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        photoLabel: photoLabel ?? this.photoLabel,
        photoUrl: photoUrl ?? this.photoUrl,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState(addresses: []);

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getProfile();
      final user = data['user'] as Map<String, dynamic>? ?? data;
      state = state.copyWith(
        name: user['name'] as String? ?? '',
        phone: user['phone'] as String? ?? '',
        photoUrl: user['photo_url'] as String?,
        isLoading: false,
      );
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadAddresses() async {
    try {
      final data = await api.getAddresses();
      final addresses = data.map((j) => Address(
        label: j['label'] as String? ?? '',
        line: j['line'] as String? ?? j['address'] as String? ?? '',
      )).toList();
      state = state.copyWith(addresses: addresses);
    } on ApiException {
      // Keep existing state
    }
  }

  Future<bool> addAddress(String label, String line) async {
    try {
      await api.createAddress({'label': label, 'address': line});
      await loadAddresses();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> removeAddress(String id) async {
    try {
      await api.deleteAddress(id);
      await loadAddresses();
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> updateAddress(String id, String line) async {
    try {
      await api.updateAddress(id, {'address': line});
      await loadAddresses();
      return true;
    } on ApiException {
      return false;
    }
  }

  void toggleFav() => state = state.copyWith(fav: !state.fav);

  void updateDetails({required String name, required String phone, String? photoLabel}) =>
      state = state.copyWith(name: name, phone: phone, photoLabel: photoLabel);

  void updateAddressLine(int i, String line) {
    final next = List.of(state.addresses);
    next[i] = Address(label: next[i].label, line: line);
    state = state.copyWith(addresses: next);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
