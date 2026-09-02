class Address {
  const Address({this.id, required this.label, required this.line, this.latitude, this.longitude});

  /// Backend row id — null for addresses that only exist client-side (e.g.
  /// the synthetic "Current location" entry in the schedule screen), which
  /// can't be saved via `PUT /customer/addresses/{id}`.
  final String? id;
  final String label;
  final String line;

  /// Null when the address was typed by hand with no location picked —
  /// callers that need a distance-based estimate should fall back gracefully.
  final double? latitude;
  final double? longitude;
}
