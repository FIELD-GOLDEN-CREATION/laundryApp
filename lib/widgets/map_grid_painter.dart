import 'package:flutter/material.dart';

/// Stylised map background — faint grid lines plus two diagonal "roads" —
/// shared by every screen that shows a map preview without a real map
/// provider behind it (schedule pickup, admin live driver map).
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const gap = 36.0;
    for (var x = 0.0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // A couple of "roads".
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.62), Offset(size.width, size.height * 0.34), road);
    canvas.drawLine(Offset(size.width * 0.22, 0), Offset(size.width * 0.42, size.height), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
