import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;

  static const _slides = [
    ('assets/images/Select-bro.svg', 'Choose your laundry partner', 'Explore trusted nearby vendors and choose the service that fits your clothes and your schedule.'),
    ('assets/images/home.jpg', 'Book pickup from home', 'Select Home, Office, or use Locate me to send your pickup address from GPS.'),
    ('assets/images/delivery.svg', 'Pickup and delivery made simple', 'A delivery partner collects your laundry and brings it back when it is ready.'),
    ('assets/images/Laundry and dry cleaning.svg', 'Laundry and cleaning, handled', 'Track every step, chat with your vendor, and enjoy a cleaner week.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _finish, child: Text('Skip', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)))),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final slide = _slides[i];
                  final svg = slide.$1.endsWith('.svg');
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 270, width: double.infinity, child: ClipRRect(borderRadius: BorderRadius.circular(26), child: svg ? SvgPicture.asset(slide.$1, fit: BoxFit.contain) : Image.asset(slide.$1, fit: BoxFit.cover))),
                        const SizedBox(height: 34),
                        Text(slide.$2, textAlign: TextAlign.center, style: AppText.serif(fontSize: 27)),
                        const SizedBox(height: 12),
                        Text(slide.$3, textAlign: TextAlign.center, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 0; i < _slides.length; i++) AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 4), width: i == _index ? 24 : 8, height: 8, decoration: BoxDecoration(color: i == _index ? AppColors.teal : AppColors.creamDark, borderRadius: BorderRadius.circular(99)))]),
            Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 22), child: SizedBox(width: double.infinity, child: Material(color: AppColors.teal, borderRadius: BorderRadius.circular(18), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () { if (last) { _finish(); } else { _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic); } }, child: Container(height: 54, alignment: Alignment.center, child: Text(last ? 'Start exploring' : 'Next', style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.cream))))))),
          ],
        ),
      ),
    );
  }
}
