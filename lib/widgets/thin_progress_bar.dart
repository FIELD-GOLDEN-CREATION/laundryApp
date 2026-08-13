import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// The thin rounded progress track reused for machine capacity, driver
/// handoff progress, vendor queue load, and report-metric bars.
class ThinProgressBar extends StatelessWidget {
  const ThinProgressBar({
    super.key,
    required this.fraction,
    required this.fillColor,
    this.height = 7,
    this.trackColor = AppColors.cream,
  });

  final double fraction;
  final Color fillColor;
  final double height;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: height,
        color: trackColor,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0, 1),
          child: Container(height: height, color: fillColor),
        ),
      ),
    );
  }
}
