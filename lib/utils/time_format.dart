/// Formats a timestamp as a local 12-hour clock string, e.g. "9:12 AM".
/// Shared by the vendor and customer order-tracking timelines so both read
/// the same `completed_at`/`created_at` values the same way.
String formatClockTime(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $suffix';
}
