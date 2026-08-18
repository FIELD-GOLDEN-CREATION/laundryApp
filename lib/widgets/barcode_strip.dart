import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// The decorative barcode strip on the vendor garment tag / handoff screens.
/// Ported from the source's deterministic `BARCODE` pattern (not random):
/// bar i is 3px wide every 4th bar, 2px every 3rd, else 1px; opacity drops
/// to .55 every 5th bar.
class BarcodeStrip extends StatelessWidget {
  const BarcodeStrip({super.key, this.height = 40, this.barCount = 34});

  final double height;
  final int barCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < barCount; i++) ...[
            if (i != 0) const SizedBox(width: 3),
            Container(
              width: i % 4 == 0 ? 3 : (i % 3 == 0 ? 2 : 1),
              height: height,
              color: AppColors.slate.withValues(alpha: i % 5 == 0 ? 0.55 : 1),
            ),
          ],
        ],
      ),
    );
  }
}
