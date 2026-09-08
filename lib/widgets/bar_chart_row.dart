import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// One bar in a [BarChartRow]. [stackedFraction]/[stackedColor] draw a
/// second segment anchored to the bottom of the bar (used for the "orders
/// vs cancellations" report chart); omit them for a plain single-color bar.
class BarDatum {
  const BarDatum({required this.heightFraction, required this.color, this.label, this.stackedFraction, this.stackedColor});

  final double heightFraction;
  final Color color;
  final String? label;
  final double? stackedFraction;
  final Color? stackedColor;
}

/// Bottom-aligned bar chart reused for the vendor dashboard's weekly
/// revenue bars, vendor earnings' monthly bars, the admin dashboard's
/// hourly velocity bars, and the admin reports stacked bar chart — all four
/// are the same "row of flex bars anchored to the bottom" shape in the
/// source, differing only in whether each bar has a label underneath and
/// whether it's a single color or a stacked two-tone segment.
class BarChartRow extends StatelessWidget {
  const BarChartRow({
    super.key,
    required this.bars,
    required this.height,
    this.gap = 7,
    this.barRadius = 5,
    this.labelColor = AppColors.tabInactive,
  });

  final List<BarDatum> bars;
  final double height;
  final double gap;
  final double barRadius;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < bars.length; i++) ...[
            if (i != 0) SizedBox(width: gap),
            Expanded(child: _Bar(datum: bars[i], radius: barRadius, labelColor: labelColor)),
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.datum, required this.radius, required this.labelColor});

  final BarDatum datum;
  final double radius;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final value = datum.heightFraction.clamp(0.02, 1.0);
    final topRadius = Radius.circular(radius);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Faint full-height track so every column reads against a
              // shared baseline instead of floating at an arbitrary height.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: datum.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.vertical(top: topRadius),
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, _) => FractionallySizedBox(
                  heightFactor: animatedValue,
                  widthFactor: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: topRadius),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [datum.color.withValues(alpha: 0.82), datum.color],
                        ),
                      ),
                      child: datum.stackedFraction == null
                          ? null
                          : Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: datum.heightFraction <= 0
                                    ? 0
                                    : (datum.stackedFraction! / datum.heightFraction).clamp(0.0, 1.0),
                                child: DecoratedBox(decoration: BoxDecoration(color: datum.stackedColor)),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (datum.label != null) ...[
          const SizedBox(height: 6),
          Text(
            datum.label!,
            style: AppText.sans(fontSize: 9, fontWeight: FontWeight.w800, color: labelColor),
          ),
        ],
      ],
    );
  }
}
