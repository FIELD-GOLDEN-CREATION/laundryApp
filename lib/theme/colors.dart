import 'package:flutter/widgets.dart';

/// Design tokens ported 1:1 from the Claude Design source
/// (design-source/Laundry Customer App.dc.html).
abstract final class AppColors {
  static const teal = Color(0xFF1A5C58);
  static const amber = Color(0xFFD4841A);
  static const slate = Color(0xFF2C3E50);
  static const muted = Color(0xFF64748B);
  static const cream = Color(0xFFF5F0E8);
  static const creamDark = Color(0xFFEDE7D9);
  static const tealMuted = Color(0xFFE8F2F1);
  static const amberLight = Color(0xFFFDF3E3);
  static const white = Color(0xFFFFFFFF);

  // Added for the Vendor/Admin modules.
  static const mint = Color(0xFF8FD6C4);
  static const danger = Color(0xFFC0553F);
  static const dangerLight = Color(0xFFFBE9E4);
  static const tabInactive = Color(0xFF9AA5A3);

  // Added for the Driver module.
  static const success = Color(0xFF1F8A5F);
  static const successLight = Color(0xFFE6F4EC);
  static const rust = Color(0xFFB64A35);
}
