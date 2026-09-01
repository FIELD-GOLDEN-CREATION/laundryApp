import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../utils/num_helper.dart';

const kWeekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const kDefaultWorkingDays = [true, false, true, true, false, false, true];
const kVendorLanguageOptions = ['English', 'Swahili'];
const _kVendorLangKey = 'prefs_vendor_language';

/// One photo in the shop's gallery. Needs its backend id so it can be
/// deleted later — `/vendor/shop/photos/{id}`.
class VendorShopPhoto {
  const VendorShopPhoto({required this.id, required this.url});
  final String id;
  final String url;
}

class VendorProfileState {
  VendorProfileState({
    required this.shopTitle,
    required this.bio,
    required this.photoUrl,
    required this.language,
    required this.officeAddress,
    this.latitude,
    this.longitude,
    required this.workingDays,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    required this.shopPhotos,
    required this.lastUpdated,
    this.isLoading = false,
    this.uploadingProfilePhoto = false,
    this.uploadingShopPhoto = false,
    this.locating = false,
  });

  final String shopTitle;
  final String bio;

  /// Real, uploaded photo URL (ImgBB) — empty until the vendor sets one.
  final String photoUrl;
  final String language;
  final String officeAddress;

  /// GPS coordinates behind [officeAddress] when it was set via "use my
  /// current location" rather than typed — needed for real distance-based
  /// delivery quotes, not just display.
  final double? latitude;
  final double? longitude;
  final List<bool> workingDays;
  final String openTime;
  final String closeTime;
  final bool isOpen;
  final List<VendorShopPhoto> shopPhotos;
  final DateTime lastUpdated;
  final bool isLoading;
  final bool uploadingProfilePhoto;
  final bool uploadingShopPhoto;
  final bool locating;

  /// Fallback initials shown until a real [photoUrl] is uploaded.
  String get photoLabel => shopTitle.isNotEmpty ? shopTitle : 'Shop';

  String get scheduleSummary {
    final days = [for (var i = 0; i < workingDays.length; i++) if (workingDays[i]) kWeekdayLabels[i]];
    if (days.isEmpty) return 'No working days set';
    return '${days.join(', ')} · $openTime – $closeTime';
  }

  VendorProfileState copyWith({
    String? shopTitle,
    String? bio,
    String? photoUrl,
    String? language,
    String? officeAddress,
    double? latitude,
    double? longitude,
    List<bool>? workingDays,
    String? openTime,
    String? closeTime,
    bool? isOpen,
    List<VendorShopPhoto>? shopPhotos,
    bool? isLoading,
    bool? uploadingProfilePhoto,
    bool? uploadingShopPhoto,
    bool? locating,
  }) =>
      VendorProfileState(
        shopTitle: shopTitle ?? this.shopTitle,
        bio: bio ?? this.bio,
        photoUrl: photoUrl ?? this.photoUrl,
        language: language ?? this.language,
        officeAddress: officeAddress ?? this.officeAddress,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        workingDays: workingDays ?? this.workingDays,
        openTime: openTime ?? this.openTime,
        closeTime: closeTime ?? this.closeTime,
        isOpen: isOpen ?? this.isOpen,
        shopPhotos: shopPhotos ?? this.shopPhotos,
        lastUpdated: DateTime.now(),
        isLoading: isLoading ?? this.isLoading,
        uploadingProfilePhoto: uploadingProfilePhoto ?? this.uploadingProfilePhoto,
        uploadingShopPhoto: uploadingShopPhoto ?? this.uploadingShopPhoto,
        locating: locating ?? this.locating,
      );
}

class VendorProfileNotifier extends Notifier<VendorProfileState> {
  @override
  VendorProfileState build() => VendorProfileState(
    shopTitle: '',
    bio: '',
    photoUrl: '',
    language: kVendorLanguageOptions.first,
    officeAddress: '',
    workingDays: List.of(kDefaultWorkingDays),
    openTime: '8:00 AM',
    closeTime: '8:00 PM',
    isOpen: true,
    shopPhotos: const [],
    lastUpdated: DateTime.now(),
  );

  /// Loads both the shop profile (backend) and the language preference
  /// (device-local — the `shops` table has no language column, and this is
  /// purely a per-device UI setting, the same way the customer app's
  /// language preference works).
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_kVendorLangKey) ?? kVendorLanguageOptions.first;
    try {
      final data = await api.getVendorShop();
      final shop = data['data'] as Map<String, dynamic>? ?? data;
      final hours = shop['operating_hours'] as Map<String, dynamic>? ?? {};
      final photosJson = (shop['photos'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      state = state.copyWith(
        shopTitle: shop['name'] as String? ?? '',
        bio: shop['description'] as String? ?? '',
        photoUrl: shop['image_url'] as String? ?? '',
        officeAddress: shop['address'] as String? ?? '',
        latitude: parseDouble(shop['latitude']),
        longitude: parseDouble(shop['longitude']),
        openTime: hours['open'] as String? ?? '8:00 AM',
        closeTime: hours['close'] as String? ?? '8:00 PM',
        isOpen: shop['is_open'] as bool? ?? true,
        shopPhotos: [
          for (final p in photosJson)
            if (p['id'] != null && p['url'] != null) VendorShopPhoto(id: '${p['id']}', url: p['url'] as String),
        ],
        language: lang,
        isLoading: false,
      );
    } on ApiException {
      state = state.copyWith(language: lang, isLoading: false);
    }
  }

  /// Pushes every editable shop field to the backend. Called after each
  /// individual field edit (see setters below) rather than behind a
  /// separate Save button — matches the screen's "auto-saves as it changes"
  /// design, which previously only ever updated local state.
  Future<void> saveProfile() async {
    try {
      await api.updateVendorShop({
        'name': state.shopTitle,
        'description': state.bio,
        'address': state.officeAddress,
        if (state.latitude != null) 'latitude': state.latitude,
        if (state.longitude != null) 'longitude': state.longitude,
        'operating_hours': {
          'open': state.openTime,
          'close': state.closeTime,
        },
        'is_open': state.isOpen,
        'working_days': kWeekdayLabels.asMap().entries
            .where((e) => state.workingDays[e.key])
            .map((e) => e.value)
            .toList(),
      });
    } on ApiException {
      // Keep the local edit; it resyncs next time loadProfile() runs.
    }
  }

  void updateShopTitle(String v) {
    state = state.copyWith(shopTitle: v);
    saveProfile();
  }

  void updateBio(String v) {
    state = state.copyWith(bio: v);
    saveProfile();
  }

  void updateOfficeAddress(String v) {
    state = state.copyWith(officeAddress: v);
    saveProfile();
  }

  /// Sets the office address from a GPS fix — takes the raw lat/lng (for the
  /// database and delivery-fee math) but stores the reverse-geocoded street
  /// address as the human-readable value, the same "use my current
  /// location" contract the customer app's schedule screen uses.
  void setLocationFromGps({required String address, required double lat, required double lng}) {
    state = state.copyWith(officeAddress: address, latitude: lat, longitude: lng);
    saveProfile();
  }

  void toggleWorkingDay(int i) {
    final next = List.of(state.workingDays);
    next[i] = !next[i];
    state = state.copyWith(workingDays: next);
    saveProfile();
  }

  void updateOpenTime(String v) {
    state = state.copyWith(openTime: v);
    saveProfile();
  }

  void updateCloseTime(String v) {
    state = state.copyWith(closeTime: v);
    saveProfile();
  }

  void toggleOpen() {
    state = state.copyWith(isOpen: !state.isOpen);
    saveProfile();
  }

  Future<void> updateLanguage(String v) async {
    state = state.copyWith(language: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVendorLangKey, v);
  }

  /// Uploads a picked profile photo to ImgBB, then saves the resulting URL
  /// as the shop's `image_url` — this is what customers see as the shop's
  /// avatar/hero image.
  Future<bool> uploadProfilePhoto(File file) async {
    state = state.copyWith(uploadingProfilePhoto: true);
    try {
      final url = await api.uploadImage(file);
      if (url.isEmpty) {
        state = state.copyWith(uploadingProfilePhoto: false);
        return false;
      }
      await api.updateVendorShop({'image_url': url});
      state = state.copyWith(photoUrl: url, uploadingProfilePhoto: false);
      return true;
    } on ApiException {
      state = state.copyWith(uploadingProfilePhoto: false);
      return false;
    }
  }

  Future<bool> addShopPhotoFromFile(File file) async {
    if (state.shopPhotos.length >= 6) return false;
    state = state.copyWith(uploadingShopPhoto: true);
    try {
      final url = await api.uploadImage(file);
      if (url.isEmpty) {
        state = state.copyWith(uploadingShopPhoto: false);
        return false;
      }
      return await _persistShopPhoto(url);
    } on ApiException {
      state = state.copyWith(uploadingShopPhoto: false);
      return false;
    }
  }

  Future<bool> addShopPhotoFromUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty || state.shopPhotos.length >= 6) return false;
    state = state.copyWith(uploadingShopPhoto: true);
    return _persistShopPhoto(trimmed);
  }

  Future<bool> _persistShopPhoto(String url) async {
    try {
      final data = await api.addVendorShopPhoto({'url': url});
      final j = data['data'] as Map<String, dynamic>? ?? data;
      final id = j['id'];
      if (id == null) {
        state = state.copyWith(uploadingShopPhoto: false);
        return false;
      }
      state = state.copyWith(
        shopPhotos: [...state.shopPhotos, VendorShopPhoto(id: '$id', url: url)],
        uploadingShopPhoto: false,
      );
      return true;
    } on ApiException {
      state = state.copyWith(uploadingShopPhoto: false);
      return false;
    }
  }

  Future<bool> removeShopPhoto(int i) async {
    if (i < 0 || i >= state.shopPhotos.length) return false;
    final photo = state.shopPhotos[i];
    final id = int.tryParse(photo.id);
    if (id != null) {
      try {
        await api.deleteVendorShopPhoto(id);
      } on ApiException {
        return false;
      }
    }
    final next = List.of(state.shopPhotos)..removeAt(i);
    state = state.copyWith(shopPhotos: next);
    return true;
  }
}

final vendorProfileProvider = NotifierProvider<VendorProfileNotifier, VendorProfileState>(VendorProfileNotifier.new);

/// Vendor-side counterpart of the customer app's `clientLabel` — picks the
/// Swahili string when the vendor's saved preference is Swahili.
String vendorLabel(String english, String swahili, String language) => language == 'Swahili' ? swahili : english;
