class Address {
  const Address({required this.label, required this.line, this.latitude, this.longitude});

  final String label;
  final String line;

  /// Null when the address was typed by hand with no location picked —
  /// callers that need a distance-based estimate should fall back gracefully.
  final double? latitude;
  final double? longitude;
}
