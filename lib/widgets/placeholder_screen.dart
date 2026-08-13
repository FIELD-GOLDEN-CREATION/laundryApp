import 'package:flutter/material.dart';

import '../theme/text_styles.dart';

/// Temporary stand-in for a Vendor/Admin screen not yet built out — same
/// role this played for every customer screen early in the first build.
/// Each real screen file replaces this with its actual content in a later
/// phase; the route registration doesn't change.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label, style: AppText.serif(fontSize: 22))));
  }
}
