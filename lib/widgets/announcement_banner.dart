import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// A compact brand strip shared by customer surfaces. The right-hand message
/// rotates so the header feels alive without taking space from the page.
class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  static const _messages = ['OFFERS', 'DISCOUNT', 'FREE PICKUP', 'NEW THIS WEEK'];
  var _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(color: AppColors.slate),
      child: Row(
        children: [
          Text('LAUNDRY', style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.cream, letterSpacing: 1.3)),
          const Spacer(),
          const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.amber),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(animation), child: child)),
            child: Text(_messages[_index], key: ValueKey(_messages[_index]), style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.cream, letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }
}
