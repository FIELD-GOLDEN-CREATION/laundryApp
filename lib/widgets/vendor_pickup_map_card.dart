import 'package:flutter/material.dart';

import '../core/icons/app_icons.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'map_grid_painter.dart';

/// The stylised "shop → client" map card — grid background, curved route
/// line, shop/client pins, address line and distance/time stats — shared by
/// the Vendor Order Detail screen and the "Accept order" sheet's pickup
/// location section (both need the same "where is this order and how far"
/// preview, just with a different customer/address/onGetDirections).
class VendorPickupMapCard extends StatelessWidget {
  const VendorPickupMapCard({
    super.key,
    required this.customerName,
    required this.address,
    required this.distanceLabel,
    required this.etaLabel,
    this.onGetDirections,
  });

  final String customerName;
  final String address;
  final String distanceLabel;
  final String etaLabel;
  final VoidCallback? onGetDirections;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.tealMuted),
                CustomPaint(painter: MapGridPainter()),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppColors.teal.withValues(alpha: 0.14)],
                    ),
                  ),
                ),
                const CustomPaint(size: Size.infinite, painter: _RouteLinePainter()),
                const Positioned(left: 26, bottom: 28, child: _ShopMarker()),
                Positioned(
                  right: 26,
                  top: 26,
                  child: Column(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.teal.withValues(alpha: 0.35), blurRadius: 12, spreadRadius: 3),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const AppIcon(AppIcons.locationPin, size: 18, color: AppColors.cream),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.creamDark),
                        ),
                        child: Text(customerName, style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(address, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700))),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _MapStat(value: distanceLabel, label: 'Distance')),
                    const SizedBox(width: 12),
                    Expanded(child: _MapStat(value: etaLabel, label: 'Est. time')),
                  ],
                ),
                if (onGetDirections != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Material(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onGetDirections,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_walk, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Get directions',
                              style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopMarker extends StatelessWidget {
  const _ShopMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.creamDark),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
      ),
      child: const Icon(Icons.storefront_outlined, color: AppColors.teal, size: 16),
    );
  }
}

class _MapStat extends StatelessWidget {
  const _MapStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.creamDark),
      ),
      child: Column(
        children: [
          Text(value, style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// Curved dotted route from the shop marker to the client's pinned location —
/// same cubic-bezier construction as `direction_screen.dart`'s route line,
/// but computed from the painter's own [size] since this map lives inside a
/// fixed-height card instead of a full-screen `Stack`.
class _RouteLinePainter extends CustomPainter {
  const _RouteLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.15, size.height * 0.82);
    final end = Offset(size.width * 0.84, size.height * 0.24);
    final midY = (start.dy + end.dy) / 2;

    final paint = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = AppColors.teal;
    for (var t = 0.0; t <= 1; t += 0.15) {
      canvas.drawCircle(_cubicPoint(start, Offset(start.dx, midY), Offset(end.dx, midY), end, t), 2, dotPaint);
    }
  }

  Offset _cubicPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    return Offset(
      u * u * u * p0.dx + 3 * u * u * t * p1.dx + 3 * u * t * t * p2.dx + t * t * t * p3.dx,
      u * u * u * p0.dy + 3 * u * u * t * p1.dy + 3 * u * t * t * p2.dy + t * t * t * p3.dy,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
