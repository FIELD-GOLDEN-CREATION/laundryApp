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
  scaffoldBackgroundColor: const Color(0xFF080D12),
  canvasColor: const Color(0xFF080D12),
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF6CC9BC),
    secondary: Color(0xFFE79A42),
    surface: Color(0xFF111A22),
    onSurface: Color(0xFFF5F0E7),
  ),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF080D12), foregroundColor: Color(0xFFF5F0E7)),
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Color(0xFF111A22)),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  textSelectionTheme: const TextSelectionThemeData(cursorColor: Color(0xFF6CC9BC)),
);
