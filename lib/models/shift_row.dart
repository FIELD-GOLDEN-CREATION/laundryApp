import 'package:flutter/widgets.dart';

/// One completed/cancelled task line in the Shift dashboard's "Shift so
/// far" list.
class ShiftRow {
  const ShiftRow({required this.id, required this.who, required this.meta, required this.amount, required this.dot});

  final String id;
  final String who;
  final String meta;
  final String amount;
  final Color dot;
}
