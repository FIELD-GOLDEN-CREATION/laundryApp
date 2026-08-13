import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// The two recurring selected/unselected color pairings used by every
/// bordered-pill chip in the Vendor/Admin screens (ports the source's
/// per-screen `on ? X : Y` inline pattern into two named schemes so call
/// sites don't repeat the same four colors).
enum ChipVariant {
  /// Selected = solid teal fill, cream text (range/agent/transport chips,
  /// garment chips).
  solid,

  /// Selected = teal-tinted fill, teal text (hour/period chips,
  /// turnaround picker) — the same pairing as the customer app's `sel()`.
  muted,
}

/// Bordered selectable pill, optionally two-line (label + sub), reused
/// across the Vendor/Admin filter chips, garment chips, and the turnaround
/// picker.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.sub,
    this.variant = ChipVariant.solid,
    this.borderRadius = 999,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    this.fontSize = 12.5,
    this.textAlign = TextAlign.center,
  });

  final String label;
  final String? sub;
  final bool selected;
  final VoidCallback onTap;
  final ChipVariant variant;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    switch (variant) {
      case ChipVariant.solid:
        bg = selected ? AppColors.teal : Colors.white;
        fg = selected ? AppColors.cream : AppColors.muted;
        border = selected ? AppColors.teal : AppColors.creamDark;
      case ChipVariant.muted:
        bg = selected ? AppColors.tealMuted : Colors.white;
        fg = selected ? AppColors.teal : AppColors.slate;
        border = selected ? AppColors.teal : AppColors.creamDark;
    }

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: textAlign == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(label, textAlign: textAlign, style: AppText.sans(fontSize: fontSize, fontWeight: FontWeight.w800, color: fg)),
              if (sub != null) ...[
                const SizedBox(height: 3),
                Text(
                  sub!,
                  textAlign: textAlign,
                  style: AppText.sans(fontSize: fontSize - 1.5, fontWeight: FontWeight.w700, color: fg.withValues(alpha: 0.75)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
