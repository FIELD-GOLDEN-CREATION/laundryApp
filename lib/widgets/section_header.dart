import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// The "Just for you" / "Services" / "Nearby shops" heading + "See all"
/// pattern repeated across the Home screen.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel = 'See all',
    this.padding = const EdgeInsets.fromLTRB(22, 26, 22, 12),
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.serif(fontSize: 22, color: AppColors.clientText(context))),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                seeAllLabel,
                style: AppText.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
