import 'package:flutter/widgets.dart';

/// [left]/[top] are fractional (0-1) positions within the map area.
class MapPin {
  const MapPin({required this.initial, required this.label, required this.bg, required this.left, required this.top});

  final String initial;
  final String label;
  final Color bg;
  final double left;
  final double top;
}
