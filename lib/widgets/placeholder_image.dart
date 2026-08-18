import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Stand-in for the source's `<image-slot>` — none of the shop/offer/map/
/// avatar photos have a real image behind them in the design, only a text
/// hint (e.g. "Shop storefront photo"). This reproduces that placeholder
/// look rather than inventing stock photos.
class PlaceholderImage extends StatelessWidget {
  const PlaceholderImage({super.key, required this.label, this.borderRadius = 0, this.circle = false});

  final String label;
  final double borderRadius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.clientBorder(context),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.clientSecondaryText(context)),
        ),
      ),
    );
  }
}
