import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Type scale — 'Inter' throughout, for both headings and body copy.
abstract final class AppText {
  static TextStyle serif({
    double fontSize = 22,
    Color color = AppColors.slate,
    FontStyle fontStyle = FontStyle.normal,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    color: color,
    fontStyle: fontStyle,
    // Inter has no distinct display cut the way DM Serif Display did, so
    // headings lean on a heavier weight instead of a different typeface to
    // keep them reading as headings next to the sans body copy below.
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static TextStyle sans({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color color = AppColors.slate,
    double? letterSpacing,
    double height = 1.25,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  /// Small uppercase eyebrow label (letter-spacing .09em / .06em / .05em
  /// patterns in the source, consolidated to one).
  static TextStyle eyebrow({Color color = AppColors.muted}) => sans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: 0.9,
  );
}
