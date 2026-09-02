import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      final parts = [p.street, p.subLocality, p.locality, p.administrativeArea]
          .where((s) => s != null && s.trim().isNotEmpty)
          .toSet() // drop duplicates (e.g. street == locality in sparse data)
          .toList();
      if (parts.isNotEmpty) return parts.join(', ');
    }
  } catch (_) {
    // Native geocoder unavailable (common on emulators without Play
    // Services) — fall through to the HTTP-based lookup below.
  }
  return _reverseGeocodeViaHttp(lat, lng);
}

/// HTTP fallback for [addressFromCoordinates] using OpenStreetMap's free
/// Nominatim API — doesn't depend on the device's native geocoder, so it
/// still resolves a real place name when that's unavailable or empty.
Future<String> _reverseGeocodeViaHttp(double lat, double lng) async {
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lng',
      'zoom': '16',
    });
    final response = await http
        .get(uri, headers: {'User-Agent': 'LaundryApp/1.0'})
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return '';
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final address = json['address'] as Map<String, dynamic>?;
    if (address == null) return '';
    final parts = [
      address['road'],
      address['suburb'] ?? address['neighbourhood'],
      address['city'] ?? address['town'] ?? address['village'],
      address['state'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toSet().toList();
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

final _degreeCoordinatePattern = RegExp(r'^-?\d{1,3}(\.\d+)?°\s*[NSns],\s*-?\d{1,3}(\.\d+)?°\s*[EWew]$');

/// True when [text] looks like a raw coordinate pair rather than a place
/// name — either [GeoPoint.label]'s "6.7924° S, 39.2083° E" format or a
/// bare "lat,lng" string. Saved locations captured before reverse geocoding
/// was reliable can still hold this shape, so display code checks it before
/// showing an address string to a customer.
bool looksLikeCoordinates(String text) {
  final t = text.trim();
  if (t.isEmpty) return false;
  if (_degreeCoordinatePattern.hasMatch(t)) return true;
  final parts = t.split(',');
  if (parts.length != 2) return false;
  return double.tryParse(parts[0].trim()) != null && double.tryParse(parts[1].trim()) != null;
}

final _reverseGeocodeCache = <String, Future<String>>{};

/// Memoized wrapper around [addressFromCoordinates] — widgets that display
/// the same shop's location across rebuilds or list scrolls share one
/// in-flight/completed lookup instead of re-querying per frame.
Future<String> cachedAddressFromCoordinates(double lat, double lng) {
  final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
  return _reverseGeocodeCache.putIfAbsent(key, () => addressFromCoordinates(lat, lng));
}
