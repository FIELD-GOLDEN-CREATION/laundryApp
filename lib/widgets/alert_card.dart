import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// The left-accent-border alert row shared by the Vendor dashboard's
/// "needs attention" list and the Admin dashboard's "urgent alerts" list.
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.title,
    required this.sub,
    required this.tag,
    required this.accentColor,
    required this.tagBg,
    this.onTap,
  });

  final String title;
  final String sub;
  final String tag;
  final Color accentColor;
  final Color tagBg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: AppColors.teal.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: accentColor, width: 4))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(999)),
                child: Text(tag, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: accentColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
