import 'package:flutter/widgets.dart';

class MachineStatus {
  const MachineStatus({required this.name, required this.state, required this.pct, required this.color});

  final String name;
  final String state;
  final double pct;
  final Color color;
}
