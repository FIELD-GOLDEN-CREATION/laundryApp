import 'package:flutter/widgets.dart';

class SysStatCard {
  const SysStatCard({required this.label, required this.value, required this.delta, required this.deltaFg});

  final String label;
  final String value;
  final String delta;
  final Color deltaFg;
}
