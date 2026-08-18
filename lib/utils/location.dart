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
