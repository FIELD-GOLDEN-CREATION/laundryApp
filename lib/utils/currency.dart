/// TZS has no meaningful subunit in everyday display, so amounts are
/// rounded to the nearest shilling and shown with thousands separators.
String formatTzs(num amount) {
  final digits = amount.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return 'TZS $buffer';
}
