import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../data/vendor_mock_data.dart';

/// The vendor's own shop-facing profile, edited from the Vendor Settings
/// screen. Both the Vendor dashboard header/account sheet and the
/// customer-facing Shop Detail screen (for this vendor's own listing,
/// `kShops.first`) read from this single provider, so an edit here is
/// immediately visible in both places.
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
  });

  final String shopTitle;
  final String bio;
  final String photoLabel;
  final String language;
  final String officeAddress;

  /// Mon..Sun, matches [kWeekdayLabels].
  final List<bool> workingDays;
  final String openTime;
  final String closeTime;
  final bool isOpen;

  /// Placeholder labels standing in for real shop photos (1-6), shown as a
  /// slideshow on the customer-facing Shop Detail screen.
  final List<String> shopPhotoLabels;

  final DateTime lastUpdated;

  /// e.g. "Mon, Wed, Thu, Sun · 8:00 AM – 8:00 PM".
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
  }) => VendorProfileState(
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
    // Every mutation is a "save" — stamped fresh on every copyWith so the
    // Settings screen can surface a live "Last saved" trace.
    lastUpdated: DateTime.now(),
  );
}

class VendorProfileNotifier extends Notifier<VendorProfileState> {
  @override
  VendorProfileState build() => VendorProfileState(
    shopTitle: kShops.first.name,
    bio: kShops.first.description,
    photoLabel: 'Shop photo',
    language: kVendorLanguageOptions.first,
    officeAddress: '21 Uhuru Street, Kariakoo, 2nd Floor',
    workingDays: List.of(kDefaultWorkingDays),
    openTime: '8:00 AM',
    closeTime: '8:00 PM',
    isOpen: kShops.first.isOpenNow,
    shopPhotoLabels: List.of(kDefaultVendorShopPhotos),
    lastUpdated: DateTime.now(),
  );

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
