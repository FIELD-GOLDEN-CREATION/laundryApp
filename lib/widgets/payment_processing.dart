import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// An "impressive" payment-processing animation: a spinning teal ring, a
/// counter-spinning amber arc, a gently pulsing centre (usually the provider
/// logo / card icon), and cycling dots under the copy.
class PaymentProcessing extends StatefulWidget {
  const PaymentProcessing({super.key, required this.title, required this.subtitle, this.center});

  final String title;
  final String subtitle;

  /// Logo/widget shown pulsing in the middle of the rings.
  final Widget? center;

  @override
  State<PaymentProcessing> createState() => _PaymentProcessingState();
}

class _PaymentProcessingState extends State<PaymentProcessing> with SingleTickerProviderStateMixin {
  late final AnimationController _arc = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  late final AnimationController _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _arc.dispose();
    _pulse.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 116,
          height: 116,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 116,
                height: 116,
                child: CircularProgressIndicator(strokeWidth: 4, color: AppColors.teal, backgroundColor: AppColors.tealMuted),
              ),
              RotationTransition(
                turns: _arc,
                child: const SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: 0.72,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                    color: AppColors.amber,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              ScaleTransition(
                scale: Tween(begin: 0.94, end: 1.06).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                child: widget.center ?? const _CenterMark(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(widget.title, style: AppText.serif(fontSize: 21), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        _CyclingDots(controller: _dots),
      ],
    );
  }
}

class _CenterMark extends StatelessWidget {
  const _CenterMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const Icon(Icons.credit_card, color: AppColors.cream, size: 30),
    );
  }
}

class _CyclingDots extends StatelessWidget {
  const _CyclingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _Dot(phase: (t * 3 + i) % 3),
              ),
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.phase});

  /// 0..3, where 0 is "just cycled" (full) and 2.5 fades out.
  final double phase;

  @override
  Widget build(BuildContext context) {
    final p = phase.clamp(0.0, 3.0);
    final alpha = 1 - (p / 3) * 0.85;
    final scale = 1 - (p / 3) * 0.35;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.teal.withValues(alpha: math.max(0.15, alpha)),
        ),
      ),
    );
  }
}
