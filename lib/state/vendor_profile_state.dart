import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';

const kWeekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const kDefaultWorkingDays = [true, false, true, true, false, false, true];
const kVendorLanguageOptions = ['English', 'Swahili'];
const kDefaultVendorShopPhotos = ['Storefront', 'Interior', 'Machines'];

class VendorProfileState {
  VendorProfileState({
    required this.shopTitle,
    required this.bio,
    required this.photoLabel,
    required this.language,
    required this.officeAddress,
    required this.workingDays,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
    required this.shopPhotoLabels,
    required this.lastUpdated,
    this.isLoading = false,
  });

  final String shopTitle;
  final String bio;
  final String photoLabel;
  final String language;
  final String officeAddress;
  final List<bool> workingDays;
  final String openTime;
  final String closeTime;
  final bool isOpen;
  final List<String> shopPhotoLabels;
  final DateTime lastUpdated;
  final bool isLoading;

  String get scheduleSummary {
    final days = [for (var i = 0; i < workingDays.length; i++) if (workingDays[i]) kWeekdayLabels[i]];
    if (days.isEmpty) return 'No working days set';
    return '${days.join(', ')} · $openTime – $closeTime';
  }

  VendorProfileState copyWith({
    String? shopTitle,
    String? bio,
    String? photoLabel,
    String? language,
    String? officeAddress,
    List<bool>? workingDays,
    String? openTime,
    String? closeTime,
    bool? isOpen,
    List<String>? shopPhotoLabels,
    bool? isLoading,
  }) =>
      VendorProfileState(
        shopTitle: shopTitle ?? this.shopTitle,
        bio: bio ?? this.bio,
        photoLabel: photoLabel ?? this.photoLabel,
        language: language ?? this.language,
        officeAddress: officeAddress ?? this.officeAddress,
        workingDays: workingDays ?? this.workingDays,
        openTime: openTime ?? this.openTime,
        closeTime: closeTime ?? this.closeTime,
        isOpen: isOpen ?? this.isOpen,
        shopPhotoLabels: shopPhotoLabels ?? this.shopPhotoLabels,
        lastUpdated: DateTime.now(),
        isLoading: isLoading ?? this.isLoading,
      );
}

class VendorProfileNotifier extends Notifier<VendorProfileState> {
  @override
  VendorProfileState build() => VendorProfileState(
    shopTitle: '',
    bio: '',
    photoLabel: 'Shop photo',
    language: kVendorLanguageOptions.first,
    officeAddress: '',
    workingDays: List.of(kDefaultWorkingDays),
    openTime: '8:00 AM',
    closeTime: '8:00 PM',
    isOpen: true,
    shopPhotoLabels: List.of(kDefaultVendorShopPhotos),
    lastUpdated: DateTime.now(),
  );

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await api.getVendorShop();
      final shop = data['data'] as Map<String, dynamic>? ?? data;
      final hours = shop['operating_hours'] as Map<String, dynamic>? ?? {};

      state = state.copyWith(
        shopTitle: shop['name'] as String? ?? '',
        bio: shop['description'] as String? ?? '',
        officeAddress: shop['address'] as String? ?? '',
        openTime: hours['open'] as String? ?? '8:00 AM',
        closeTime: hours['close'] as String? ?? '8:00 PM',
        isOpen: shop['is_open'] as bool? ?? true,
        isLoading: false,
      );
    } on ApiException {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveProfile() async {
    try {
      await api.updateVendorShop({
        'name': state.shopTitle,
        'description': state.bio,
        'address': state.officeAddress,
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
      // Caller can handle
    }
  }

  void updateShopTitle(String v) => state = state.copyWith(shopTitle: v);
  void updateBio(String v) => state = state.copyWith(bio: v);
  void cyclePhotoLabel() =>
      state = state.copyWith(photoLabel: state.photoLabel == 'Shop photo' ? 'New shop photo' : 'Shop photo');
  void updateLanguage(String v) => state = state.copyWith(language: v);
  void updateOfficeAddress(String v) => state = state.copyWith(officeAddress: v);

  void toggleWorkingDay(int i) {
    final next = List.of(state.workingDays);
    next[i] = !next[i];
    state = state.copyWith(workingDays: next);
  }

  void updateOpenTime(String v) => state = state.copyWith(openTime: v);
  void updateCloseTime(String v) => state = state.copyWith(closeTime: v);
  void toggleOpen() => state = state.copyWith(isOpen: !state.isOpen);

  void addShopPhoto() {
    if (state.shopPhotoLabels.length >= 6) return;
    final next = List.of(state.shopPhotoLabels)..add('Shop photo ${state.shopPhotoLabels.length + 1}');
    state = state.copyWith(shopPhotoLabels: next);
  }

  void removeShopPhoto(int i) {
    final next = List.of(state.shopPhotoLabels)..removeAt(i);
    state = state.copyWith(shopPhotoLabels: next);
  }
}

final vendorProfileProvider = NotifierProvider<VendorProfileNotifier, VendorProfileState>(VendorProfileNotifier.new);
