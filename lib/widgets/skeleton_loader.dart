import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Wraps a subtree of static placeholder shapes ([SkeletonBox], [SkeletonLine])
/// in one moving-gradient shimmer sweep, driven by a single [AnimationController].
///
/// Only ONE controller/[ShaderMask] exists per [Skeleton] instance no matter
/// how many placeholder shapes are nested inside it — wrap the whole skeleton
/// region (e.g. an entire placeholder list) in one [Skeleton], not each
/// row/card individually. The shapes themselves are inert [Container]s; the
/// shader just sweeps a lightening band across whatever is on screen.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A relative *lightening* band rather than a second absolute color —
    // dark mode's clientSurfaceRaised is darker than clientBorder, so
    // reusing it as a literal highlight would invert the sweep.
    final highlightAlpha = AppColors.isClientDark(context) ? 0.10 : 0.55;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: highlightAlpha),
            Colors.transparent,
          ],
          stops: const [0.35, 0.5, 0.65],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          transform: _SlidingGradientTransform(slidePercent: _controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Translates the gradient across [bounds] as [slidePercent] goes 0→1, so the
/// highlight band travels from fully off-screen-left to fully off-screen-right
/// and the loop's reset at t=1→0 is invisible.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (2 * slidePercent - 1), 0, 0);
  }
}

/// A static "bone" placeholder shape — a rounded rect or circle filled with
/// the theme's muted border tone. Rendered under a [Skeleton]'s single
/// [ShaderMask]; does not animate itself.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.borderRadius = 8, this.circle = false});

  final double? width;
  final double? height;
  final double borderRadius;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.clientBorder(context),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(borderRadius),
        ),
      );
}

/// Convenience alias of [SkeletonBox] sized like a line of text — used for
/// title/subtitle/price placeholder lines.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, required this.width, this.height = 12});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SkeletonBox(width: width, height: height, borderRadius: 4);
}
