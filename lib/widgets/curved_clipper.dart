import 'package:flutter/widgets.dart';

class CurvedTopClipper extends CustomClipper<Path> {
  const CurvedTopClipper({this.depth = 28, this.lift = -18});

  final double depth;
  final double lift;

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, depth)
    ..quadraticBezierTo(size.width * 0.5, lift, size.width, depth)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
