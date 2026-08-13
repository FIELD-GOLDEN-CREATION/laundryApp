import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Plays a quick horizontal shake on [child] each time [trigger] increments.
/// Used to reject input that would exceed a field's limit (e.g. a 10-digit
/// phone number) without silently dropping keystrokes.
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        if (v == 0) return child!;
        final dx = math.sin(v * math.pi * 5) * (1 - v) * 9;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
