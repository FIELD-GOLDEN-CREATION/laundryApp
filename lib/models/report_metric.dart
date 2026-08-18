import 'package:flutter/widgets.dart';

class ReportMetric {
  const ReportMetric({
    required this.label,
    required this.value,
    required this.pct,
    required this.pctFg,
    required this.note,
    required this.bar,
  });

  final String label;
  final String value;
  final String pct;
  final Color pctFg;
  final String note;
  final double bar;
}
