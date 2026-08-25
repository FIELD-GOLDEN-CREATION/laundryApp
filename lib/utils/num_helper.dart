/// Safely parse a value that may come as String or num into a num.
/// Laravel's JSON serializer often returns numeric fields as strings
/// (e.g. "50.00" instead of 50), so we need to handle both.
num? parseNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

/// Convenience for double.
double? parseDouble(dynamic v) => parseNum(v)?.toDouble();

/// Convenience for int.
int? parseInt(dynamic v) => parseNum(v)?.toInt();
