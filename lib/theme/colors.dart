import 'package:flutter/material.dart';

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

  static bool isClientDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color clientSurface(BuildContext context) =>
      isClientDark(context) ? const Color(0xFF111A22) : Colors.white;
  static Color clientSurfaceRaised(BuildContext context) =>
      isClientDark(context) ? const Color(0xFF182631) : Colors.white;
  static Color clientText(BuildContext context) =>
      isClientDark(context) ? const Color(0xFFF5F0E7) : slate;
  static Color clientSecondaryText(BuildContext context) =>
      isClientDark(context) ? const Color(0xFFAAB8C2) : muted;
  static Color clientBorder(BuildContext context) =>
      isClientDark(context) ? const Color(0xFF2A3B47) : creamDark;

  /// Bright teal/amber text that stays readable on dark surfaces.
  static Color clientTealText(BuildContext context) =>
      isClientDark(context) ? const Color(0xFF6CC9BC) : teal;
  static Color clientAmberText(BuildContext context) =>
      isClientDark(context) ? const Color(0xFFE79A42) : amber;

  /// Soft pill backgrounds: light tints in light mode, translucent whites in dark mode.
  static Color clientPillTeal(BuildContext context) =>
      isClientDark(context) ? Colors.white.withValues(alpha: 0.09) : tealMuted;
  static Color clientPillAmber(BuildContext context) =>
      isClientDark(context) ? Colors.white.withValues(alpha: 0.09) : amberLight;
  static Color clientPillDanger(BuildContext context) => isClientDark(context)
      ? Colors.white.withValues(alpha: 0.09)
      : dangerLight;
  static Color clientPillSuccess(BuildContext context) => isClientDark(context)
      ? Colors.white.withValues(alpha: 0.09)
      : successLight;

  /// Text-field fill color.
  static Color clientInputFill(BuildContext context) =>
      isClientDark(context) ? const Color(0xFF182631) : Colors.white;

  /// Muted icon color that stays visible on dark surfaces.
  static Color clientMutedIcon(BuildContext context) =>
      isClientDark(context) ? const Color(0xFF8FA1AD) : muted;

  // Sky blue-white theme tokens (customer only).
  static const skyBg = Color(0xFF0E4E8A);
  static const skyDeep = Color(0xFF0C3E6E);
  static const skyBlue = Color(0xFF1B6FAE);
  static const skyCloud = Color(0xFF2E7CC2);
  static const skyNavy = Color(0xFF0F2B46);
}
