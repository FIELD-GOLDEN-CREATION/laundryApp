import 'dart:convert';
import 'dart:math' as math;

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

/// Straight-line distance between two GPS points in kilometers. Mirrors
/// `DeliveryFee::haversineKm` in the Laravel backend (same radius, same
/// formula) so a customer's "X km away" here never disagrees with the
/// delivery fee they're quoted at checkout for the same shop.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLng = _degToRad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_degToRad(lat1)) * math.cos(_degToRad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * (math.pi / 180);

/// One forward-geocoding result from Nominatim's `/search` endpoint —
/// a typed address candidate with the coordinates needed to pin it on
/// [flutter_map] later (schedule screen, direction screen).
class AddressSuggestion {
  const AddressSuggestion({required this.label, required this.latitude, required this.longitude});

  final String label;
  final double latitude;
  final double longitude;
}

/// Dar es Salaam's bounding box (left,top,right,bottom) — biases Nominatim
/// results toward the city without excluding the rest of Tanzania, so a
/// customer typing a Dar street sees it ranked above a same-named one
/// elsewhere in the country.
const _darEsSalaamViewbox = '39.05,-7.05,39.55,-6.55';

/// Address autocomplete via OpenStreetMap's free Nominatim `/search` API —
/// the forward-geocoding counterpart to [_reverseGeocodeViaHttp]. Returns at
/// most 5 candidates; empty (never throws) on a short query, network error,
/// or no matches, so callers can just hide the suggestion list.
Future<List<AddressSuggestion>> searchAddressSuggestions(String query) async {
  final trimmed = query.trim();
  if (trimmed.length < 3) return const [];
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': trimmed,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '5',
      'countrycodes': 'tz',
      'viewbox': _darEsSalaamViewbox,
      'bounded': '0', // bias toward Dar, don't hard-exclude the rest of TZ
    });
    final response = await http
        .get(uri, headers: {'User-Agent': 'LaundryApp/1.0'})
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return const [];
    final results = jsonDecode(response.body) as List<dynamic>;
    return results
        .map((r) => _parseSuggestion(r as Map<String, dynamic>))
        .whereType<AddressSuggestion>()
        .toList();
  } catch (_) {
    return const [];
  }
}

AddressSuggestion? _parseSuggestion(Map<String, dynamic> json) {
  final lat = double.tryParse('${json['lat']}');
  final lon = double.tryParse('${json['lon']}');
  if (lat == null || lon == null) return null;
  return AddressSuggestion(label: _formatSuggestion(json), latitude: lat, longitude: lon);
}

/// Builds a "street, ward/suburb, district, city, region" label from
/// Nominatim's address parts, narrowest first (mirrors
/// [_reverseGeocodeViaHttp]'s ordering) — falls back to Nominatim's own
/// `display_name` when structured fields are missing.
String _formatSuggestion(Map<String, dynamic> json) {
  final address = json['address'] as Map<String, dynamic>?;
  if (address != null) {
    final parts = [
      address['road'],
      address['suburb'] ?? address['quarter'] ?? address['neighbourhood'],
      address['city_district'] ?? address['county'],
      address['city'] ?? address['town'] ?? address['village'],
      address['state'],
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toSet().toList();
    if (parts.isNotEmpty) return parts.join(', ');
  }
  return json['display_name'] as String? ?? '';
}

final _reverseGeocodeCache = <String, Future<String>>{};

/// Memoized wrapper around [addressFromCoordinates] — widgets that display
/// the same shop's location across rebuilds or list scrolls share one
/// in-flight/completed lookup instead of re-querying per frame.
Future<String> cachedAddressFromCoordinates(double lat, double lng) {
  final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
  return _reverseGeocodeCache.putIfAbsent(key, () => addressFromCoordinates(lat, lng));
}
