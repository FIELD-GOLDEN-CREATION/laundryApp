import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// A resolved device position with a short human-readable label.
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  String get label {
    final lat = latitude.abs().toStringAsFixed(4);
    final lng = longitude.abs().toStringAsFixed(4);
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    return '$lat° $latDir, $lng° $lngDir';
  }
}

/// Fetches the device's current position. Throws [LocationException] with a
/// user-friendly message when permission is denied or location services are
/// switched off.
Future<GeoPoint> locateUser() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw const LocationException('Location permission was denied.');
  }
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationException('Location services are turned off.');
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
  return GeoPoint(latitude: position.latitude, longitude: position.longitude);
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Turns a GPS fix into a human-readable street address ("Kinondoni,
/// Dar es Salaam") via the OS's native geocoder — no server-side API key
/// needed. Falls back to '' (never throws) so callers can drop back to
/// [GeoPoint.label]'s raw coordinates when reverse geocoding can't resolve
/// anything (rural areas, geocoder unavailable, no network).
Future<String> addressFromCoordinates(double lat, double lng) async {
  try {
    final placemarks = await Geocoding().placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return '';
    final p = placemarks.first;
    final parts = [p.street, p.subLocality, p.locality, p.administrativeArea]
        .where((s) => s != null && s.trim().isNotEmpty)
        .toSet() // drop duplicates (e.g. street == locality in sparse data)
        .toList();
    return parts.join(', ');
  } catch (_) {
    return '';
  }
}

/// Combines [locateUser] and [addressFromCoordinates]: the GPS fix plus its
/// best-effort human-readable label, so every "use my current location" flow
/// (customer or vendor) shows a real address instead of raw coordinates.
class ResolvedLocation {
  const ResolvedLocation({required this.point, required this.address});
  final GeoPoint point;

  /// A real address when reverse geocoding succeeded, else "" — callers
  /// should fall back to `point.label`.
  final String address;

  /// The address when available, otherwise the raw coordinate label.
  String get displayLabel => address.isNotEmpty ? address : point.label;
}

Future<ResolvedLocation> locateUserWithAddress() async {
  final point = await locateUser();
  final address = await addressFromCoordinates(point.latitude, point.longitude);
  return ResolvedLocation(point: point, address: address);
}
