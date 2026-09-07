import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/address.dart';
import '../utils/location.dart';
import 'auth_state.dart';
import 'profile_state.dart';

const _kSourceKey = 'browse_location_source';
const _kAddressIdKey = 'browse_location_address_id';
const _kLatKey = 'browse_location_lat';
const _kLngKey = 'browse_location_lng';
const _kLabelKey = 'browse_location_label';

/// Where the customer's location — used to compute "X km away" on shop
/// cards — comes from: a saved profile address, or a live GPS fix. Kept
/// separate from `ScheduleState` (schedule_state.dart), which is scoped to
/// one order's pickup address and gets discarded per checkout; this one is
/// session-long browsing context read by every shop card at once.
enum BrowseLocationSource { none, savedAddress, gps }

class BrowseLocationState {
  const BrowseLocationState({
    this.source = BrowseLocationSource.none,
    this.savedAddressId,
    this.lat,
    this.lng,
    this.label = '',
    this.isLocating = false,
    this.hasPrompted = false,
    this.error,
    this.prefetchedLat,
    this.prefetchedLng,
    this.prefetchedLabel,
    this.isPrefetching = false,
  });

  final BrowseLocationSource source;

  /// Backend `Address.id` when [source] is `savedAddress` — an id rather
  /// than a list index so a restored choice survives addresses being
  /// added/removed/reordered.
  final String? savedAddressId;

  /// The active, resolved coordinates used for distance math.
  final double? lat;
  final double? lng;
  final String label;

  /// True while a live GPS fix is in flight for the "Use my current
  /// location" option in the picker sheet.
  final bool isLocating;

  /// Set once the picker sheet has been shown (or explicitly skipped) this
  /// session/restore, so Search doesn't re-trigger it every visit.
  final bool hasPrompted;

  /// Last GPS error message, cleared on the next attempt.
  final String? error;

  /// Background best-effort GPS warm-up results (see [BrowseLocationNotifier.prefetch])
  /// — populated ahead of the customer ever opening the picker sheet, so
  /// tapping "Use my current location" there can resolve instantly instead
  /// of waiting on a live GPS+geocode round trip.
  final double? prefetchedLat;
  final double? prefetchedLng;
  final String? prefetchedLabel;
  final bool isPrefetching;

  bool get hasLocation => lat != null && lng != null;

  BrowseLocationState copyWith({
    BrowseLocationSource? source,
    String? savedAddressId,
    double? lat,
    double? lng,
    String? label,
    bool? isLocating,
    bool? hasPrompted,
    String? error,
    double? prefetchedLat,
    double? prefetchedLng,
    String? prefetchedLabel,
    bool? isPrefetching,
    bool clearSavedAddressId = false,
    bool clearError = false,
  }) {
    return BrowseLocationState(
      source: source ?? this.source,
      savedAddressId: clearSavedAddressId ? null : (savedAddressId ?? this.savedAddressId),
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      label: label ?? this.label,
      isLocating: isLocating ?? this.isLocating,
      hasPrompted: hasPrompted ?? this.hasPrompted,
      error: clearError ? null : (error ?? this.error),
      prefetchedLat: prefetchedLat ?? this.prefetchedLat,
      prefetchedLng: prefetchedLng ?? this.prefetchedLng,
      prefetchedLabel: prefetchedLabel ?? this.prefetchedLabel,
      isPrefetching: isPrefetching ?? this.isPrefetching,
    );
  }
}

class BrowseLocationNotifier extends Notifier<BrowseLocationState> {
  @override
  BrowseLocationState build() {
    // Resets everything (including hasPrompted) whenever the signed-in
    // customer changes, so one account's chosen location/addresses never
    // leak into another's session.
    ref.watch(authProvider.select((s) => s.userId));

    Future.microtask(_restore);
    Future.microtask(prefetch);
    return const BrowseLocationState();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final sourceStr = prefs.getString(_kSourceKey);
    final source = BrowseLocationSource.values.firstWhere(
      (s) => s.name == sourceStr,
      orElse: () => BrowseLocationSource.none,
    );
    if (source == BrowseLocationSource.none) return;

    final lat = prefs.getDouble(_kLatKey);
    final lng = prefs.getDouble(_kLngKey);
    final label = prefs.getString(_kLabelKey) ?? '';
    final addressId = prefs.getString(_kAddressIdKey);

    if (source == BrowseLocationSource.savedAddress && addressId != null) {
      // Prefer the live profile address (fresher coordinates in case it was
      // edited since); fall back to the persisted snapshot if it's gone.
      Address? match;
      for (final a in ref.read(profileProvider).addresses) {
        if (a.id == addressId) {
          match = a;
          break;
        }
      }
      if (match != null) {
        state = state.copyWith(
          source: source,
          savedAddressId: addressId,
          lat: match.latitude ?? lat,
          lng: match.longitude ?? lng,
          label: match.label.isNotEmpty ? match.label : match.line,
          hasPrompted: true,
        );
        return;
      }
    }

    if (lat != null && lng != null) {
      state = state.copyWith(
        source: source,
        savedAddressId: addressId,
        lat: lat,
        lng: lng,
        label: label,
        hasPrompted: true,
      );
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSourceKey, state.source.name);
    if (state.savedAddressId != null) {
      await prefs.setString(_kAddressIdKey, state.savedAddressId!);
    } else {
      await prefs.remove(_kAddressIdKey);
    }
    if (state.lat != null) await prefs.setDouble(_kLatKey, state.lat!);
    if (state.lng != null) await prefs.setDouble(_kLngKey, state.lng!);
    await prefs.setString(_kLabelKey, state.label);
  }

  void useSavedAddress(Address address) {
    state = state.copyWith(
      source: BrowseLocationSource.savedAddress,
      savedAddressId: address.id,
      lat: address.latitude,
      lng: address.longitude,
      label: address.label.isNotEmpty ? address.label : address.line,
      hasPrompted: true,
      clearError: true,
    );
    _persist();
  }

  Future<void> useCurrentLocation() async {
    // Already warmed up by `prefetch()` — promote instantly, no spinner.
    if (state.prefetchedLat != null && state.prefetchedLng != null) {
      state = state.copyWith(
        source: BrowseLocationSource.gps,
        lat: state.prefetchedLat,
        lng: state.prefetchedLng,
        label: state.prefetchedLabel ?? GeoPoint(latitude: state.prefetchedLat!, longitude: state.prefetchedLng!).label,
        hasPrompted: true,
        clearSavedAddressId: true,
        clearError: true,
      );
      _persist();
      return;
    }

    state = state.copyWith(isLocating: true, clearError: true);
    try {
      final resolved = await locateUserWithAddress();
      state = state.copyWith(
        source: BrowseLocationSource.gps,
        lat: resolved.point.latitude,
        lng: resolved.point.longitude,
        label: resolved.displayLabel,
        hasPrompted: true,
        isLocating: false,
        clearSavedAddressId: true,
      );
      _persist();
    } on LocationException catch (e) {
      state = state.copyWith(isLocating: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLocating: false, error: 'Could not get your location.');
    }
  }

  /// Best-effort, silent GPS warm-up — never surfaces errors directly (a
  /// real error only shows if the customer explicitly taps "Use my current
  /// location" in the sheet and [useCurrentLocation] also fails live).
  Future<void> prefetch() async {
    if (state.isPrefetching) return;
    state = state.copyWith(isPrefetching: true);

    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        state = state.copyWith(prefetchedLat: last.latitude, prefetchedLng: last.longitude);
        final label = await cachedAddressFromCoordinates(last.latitude, last.longitude);
        if (label.isNotEmpty) state = state.copyWith(prefetchedLabel: label);
      }
    } catch (_) {
      // No last-known fix (e.g. first-ever launch) — fine, the fresh fix
      // below still runs.
    }

    try {
      final fresh = await locateUser();
      final label = await addressFromCoordinates(fresh.latitude, fresh.longitude);
      state = state.copyWith(
        prefetchedLat: fresh.latitude,
        prefetchedLng: fresh.longitude,
        prefetchedLabel: label.isNotEmpty ? label : fresh.label,
      );
    } catch (_) {
      // Permission denied / services off — leave whatever last-known fix
      // (if any) as the warmed-up value.
    } finally {
      state = state.copyWith(isPrefetching: false);
    }
  }

  void markPrompted() => state = state.copyWith(hasPrompted: true);
}

final browseLocationProvider = NotifierProvider<BrowseLocationNotifier, BrowseLocationState>(BrowseLocationNotifier.new);
