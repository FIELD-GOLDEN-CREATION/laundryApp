import 'package:flutter/material.dart';

import '../theme/text_styles.dart';

/// The colored "big number + label" tile reused across Profile's stat row,
/// Vendor dashboard, and Admin client/driver detail screens.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, required this.bg, required this.fg});

  final String value;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppText.serif(fontSize: 24, color: fg), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}
