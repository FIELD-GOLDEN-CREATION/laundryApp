import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/shop.dart';
import '../../../state/client_preferences_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/round_back_button.dart';

class DirectionScreen extends ConsumerStatefulWidget {
  const DirectionScreen({super.key, required this.shop});

  final Shop shop;

  @override
  ConsumerState<DirectionScreen> createState() => _DirectionScreenState();
}

class _DirectionScreenState extends ConsumerState<DirectionScreen> {
  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final language = ref.watch(clientPreferencesProvider).language;

    return Scaffold(
      backgroundColor: AppColors.clientSurface(context),
      body: Stack(
        children: [
          _MapPlaceholder(shop: shop),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RoundBackButton(onPressed: () => context.pop()),
                    _GlassButton(
                      icon: Icons.my_location,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _DirectionBottomSheet(shop: shop, language: language),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.clientSurface(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.tealMuted.withValues(alpha: 0.3),
                  AppColors.clientSurface(context),
                ],
              ),
            ),
          ),
          CustomPaint(
            painter: _MapGridPainter(color: AppColors.clientBorder(context)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: MediaQuery.of(context).size.width * 0.5 - 20,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.clientSurface(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.clientBorder(context)),
                  ),
                  child: Text(
                    shop.name,
                    style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.55,
            left: MediaQuery.of(context).size.width * 0.3,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.clientSurface(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.clientBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.navigation, color: AppColors.teal, size: 16),
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _RouteLinePainter(
              color: AppColors.teal,
              start: Offset(MediaQuery.of(context).size.width * 0.3 + 16, MediaQuery.of(context).size.height * 0.55 + 16),
              end: Offset(MediaQuery.of(context).size.width * 0.5, MediaQuery.of(context).size.height * 0.35 + 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RouteLinePainter extends CustomPainter {
  _RouteLinePainter({
    required this.color,
    required this.start,
    required this.end,
  });

  final Color color;
  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    final midY = (start.dy + end.dy) / 2;
    path.cubicTo(start.dx, midY, end.dx, midY, end.dx, end.dy);

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    for (double t = 0; t <= 1; t += 0.15) {
      final point = _cubicBezier(start, Offset(start.dx, midY), Offset(end.dx, midY), end, t);
      canvas.drawCircle(point, 2, dotPaint);
    }
  }

  Offset _cubicBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    return Offset(
      u * u * u * p0.dx + 3 * u * u * t * p1.dx + 3 * u * t * t * p2.dx + t * t * t * p3.dx,
      u * u * u * p0.dy + 3 * u * u * t * p1.dy + 3 * u * t * t * p2.dy + t * t * t * p3.dy,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.clientSurface(context).withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.clientBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(child: Icon(icon, size: 20, color: AppColors.clientText(context))),
        ),
      ),
    );
  }
}

class _DirectionBottomSheet extends StatelessWidget {
  const _DirectionBottomSheet({required this.shop, required this.language});

  final Shop shop;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.clientBorder(context)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.clientBorder(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            shop.name,
            style: AppText.sans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: AppColors.clientSecondaryText(context)),
              const SizedBox(width: 6),
              Text(
                shop.distance,
                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule_outlined, size: 16, color: AppColors.clientSecondaryText(context)),
              const SizedBox(width: 6),
              Text(
                shop.hours,
                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _DirectionStep(
                icon: Icons.navigation,
                label: language == 'Swahili' ? 'Uanzisho' : 'Start',
                sublabel: language == 'Swahili' ? 'Eneo lako' : 'Your location',
                color: AppColors.teal,
              ),
              _DirectionArrow(),
              _DirectionStep(
                icon: Icons.store,
                label: shop.name,
                sublabel: language == 'Swahili' ? 'Unakwenda' : 'Destination',
                color: AppColors.amber,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.clientSurfaceRaised(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.clientBorder(context)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${shop.distanceKm.toStringAsFixed(1)} km',
                        style: AppText.sans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        language == 'Swahili' ? 'Umbali' : 'Distance',
                        style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.clientSurfaceRaised(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.clientBorder(context)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '~${(shop.distanceKm * 3).round()} min',
                        style: AppText.sans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        language == 'Swahili' ? 'Muda' : 'Est. time',
                        style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: Material(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_walk, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      language == 'Swahili' ? 'Anza Safari' : 'Start Navigation',
                      style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionStep extends StatelessWidget {
  const _DirectionStep({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
            ),
            Text(
              sublabel,
              style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
            ),
          ],
        ),
      ],
    );
  }
}

class _DirectionArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(width: 20, height: 2, color: AppColors.clientBorder(context)),
          Icon(Icons.arrow_forward, color: AppColors.clientSecondaryText(context), size: 16),
          Container(width: 20, height: 2, color: AppColors.clientBorder(context)),
        ],
      ),
    );
  }
}
