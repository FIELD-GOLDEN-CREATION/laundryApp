import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.cream,
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    primary: AppColors.teal,
    secondary: AppColors.amber,
    surface: AppColors.cream,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.teal),
);

final ThemeData clientDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  // Transparent: the shell-level background video shows through on every
  // customer page; cards and sheets carry their own dark surfaces.
  scaffoldBackgroundColor: Colors.transparent,
  canvasColor: Colors.transparent,
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF6CC9BC),
    secondary: Color(0xFFE79A42),
    surface: Color(0xFF111A22),
    onSurface: Color(0xFFF5F0E7),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF080D12),
    foregroundColor: Color(0xFFF5F0E7),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF111A22),
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color(0xFF6CC9BC),
  ),
);

/// Sky blue-white theme (customer only): deep sky-blue scaffold with the
/// cloud video behind it, white cards, navy text — brightness stays light
/// so every adaptive `client*` helper resolves to the white-card look.
final ThemeData clientSkyTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  // Transparent: the shell-level cloud video shows through on every
  // customer page; cards carry their own white surfaces.
  scaffoldBackgroundColor: Colors.transparent,
  canvasColor: Colors.transparent,
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1B6FAE),
    primary: const Color(0xFF1B6FAE),
    secondary: AppColors.amber,
    surface: Colors.white,
    onSurface: const Color(0xFF0F2B46),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color(0xFF1B6FAE),
  ),
);
