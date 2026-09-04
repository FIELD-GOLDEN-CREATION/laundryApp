import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/address.dart';
import '../services/api_service.dart';
import '../utils/num_helper.dart';

class ProfileState {
  const ProfileState({
    required this.addresses,
    this.fav = false,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.photoLabel = 'You',
    this.photoUrl,
    this.isLoading = false,
    this.uploadingProfilePhoto = false,
  });

  final List<Address> addresses;
  final bool fav;
  final String name;
  final String phone;
  final String email;
  final String photoLabel;
  final String? photoUrl;
  final bool isLoading;
  final bool uploadingProfilePhoto;

  ProfileState copyWith({
    List<Address>? addresses,
    bool? fav,
    String? name,
    String? phone,
    String? email,
    String? photoLabel,
    String? photoUrl,
    bool? isLoading,
    bool? uploadingProfilePhoto,
  }) =>
      ProfileState(
        addresses: addresses ?? this.addresses,
        fav: fav ?? this.fav,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        photoLabel: photoLabel ?? this.photoLabel,
        photoUrl: photoUrl ?? this.photoUrl,
        isLoading: isLoading ?? this.isLoading,
        uploadingProfilePhoto: uploadingProfilePhoto ?? this.uploadingProfilePhoto,
      );
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState(addresses: []);

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getProfile();
      final user = data['data'] as Map<String, dynamic>? ?? data;
      state = state.copyWith(
        name: user['name'] as String? ?? '',
        phone: user['phone'] as String? ?? '',
        email: user['email'] as String? ?? '',
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
        id: j['id'] == null ? null : '${j['id']}',
        label: j['label'] as String? ?? '',
        line: j['line'] as String? ?? j['address'] as String? ?? '',
        latitude: parseDouble(j['latitude']),
        longitude: parseDouble(j['longitude']),
      )).toList();
      state = state.copyWith(addresses: addresses);
    } on ApiException {
      // Keep existing state
    }
  }

  Future<bool> addAddress(String label, String line, {double? latitude, double? longitude}) async {
    try {
      await api.createAddress({'label': label, 'line': line, 'latitude': latitude, 'longitude': longitude});
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
      await api.updateAddress(id, {'line': line});
      await loadAddresses();
      return true;
    } on ApiException {
      return false;
    }
  }

  /// Uploads a picked profile photo to ImgBB, then saves the resulting URL
  /// as the customer's `photo_url` — mirrors the vendor app's
  /// `uploadProfilePhoto` in `vendor_profile_state.dart`.
  Future<bool> uploadProfilePhoto(XFile file) async {
    state = state.copyWith(uploadingProfilePhoto: true);
    try {
      final url = await api.uploadImage(file);
      if (url.isEmpty) {
        state = state.copyWith(uploadingProfilePhoto: false);
        return false;
      }
      await api.updateProfile({'photo_url': url});
      state = state.copyWith(photoUrl: url, uploadingProfilePhoto: false);
      return true;
    } on ApiException {
      state = state.copyWith(uploadingProfilePhoto: false);
      return false;
    }
  }

  void toggleFav() => state = state.copyWith(fav: !state.fav);

  /// Saves the edited name/phone to the backend. Applies the edit to local
  /// state optimistically so the UI updates immediately; on failure the
  /// caller should surface an error (state is left updated, it resyncs next
  /// time [loadProfile] runs).
  Future<bool> updateDetails({required String name, required String phone, String? photoLabel}) async {
    state = state.copyWith(name: name, phone: phone, photoLabel: photoLabel);
    try {
      await api.updateProfile({'name': name, 'phone': phone});
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<void> updateAddressLine(int i, String line) async {
    final current = state.addresses[i];
    final next = List.of(state.addresses);
    next[i] = Address(id: current.id, label: current.label, line: line);
    state = state.copyWith(addresses: next);
    if (current.id != null) await updateAddress(current.id!, line);
  }

  /// Removes the address at [i] from local state immediately, then deletes
  /// it on the backend if it was ever persisted there. If the backend call
  /// fails, the optimistic removal is reverted so the UI doesn't show the
  /// address as gone when it's still saved server-side.
  Future<bool> removeAddressAt(int i) async {
    final current = state.addresses[i];
    final next = List.of(state.addresses)..removeAt(i);
    state = state.copyWith(addresses: next);
    if (current.id == null) return true;
    final ok = await removeAddress(current.id!);
    if (!ok) {
      final reverted = List.of(state.addresses)..insert(i.clamp(0, state.addresses.length), current);
      state = state.copyWith(addresses: reverted);
    }
    return ok;
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
