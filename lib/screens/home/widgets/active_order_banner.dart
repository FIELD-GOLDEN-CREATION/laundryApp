import 'package:flutter/material.dart';

import '../../../core/icons/app_icons.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';

/// The "Order #LD-2481 is being washed" card that overlaps the home header,
/// including the pulsing-ring CSS animation from the source
/// (`@keyframes pulseRing`) ported to a looping AnimationController.
class ActiveOrderBanner extends StatefulWidget {
  const ActiveOrderBanner({super.key, required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<ActiveOrderBanner> createState() => _ActiveOrderBannerState();
}

class _ActiveOrderBannerState extends State<ActiveOrderBanner> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 10,
        shadowColor: AppColors.teal.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final t = _controller.value;
                          return Opacity(
                            opacity: (1 - t) * 0.55,
                            child: Transform.scale(
                              scale: 0.9 + t * 0.7,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2A7D78),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const AppIcon(AppIcons.clock, size: 21),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const AppIcon(AppIcons.chevronRightSmall, size: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
