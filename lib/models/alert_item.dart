import 'package:flutter/widgets.dart';

/// Shared by the Vendor dashboard's "needs attention" list and the Admin
/// dashboard's "urgent alerts" list — see widgets/alert_card.dart.
class AlertItem {
  const AlertItem({
    required this.title,
    required this.sub,
    required this.tag,
    required this.accentColor,
    required this.tagBg,
  });

  final String title;
  final String sub;
  final String tag;
  final Color accentColor;
  final Color tagBg;
}
