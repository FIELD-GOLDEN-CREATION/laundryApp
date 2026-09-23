import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../state/catalog_state.dart';
import '../../packages/widgets/package_showcase_card.dart';

// Package card photos come from the backend per kind (see
// ServicePackage.displayImage) — no bundled illustrations needed.

class PackagesCarousel extends ConsumerStatefulWidget {
  const PackagesCarousel({super.key});

  @override
  ConsumerState<PackagesCarousel> createState() => _PackagesCarouselState();
}

class _PackagesCarouselState extends ConsumerState<PackagesCarousel> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    // Fetch is triggered by home_screen.dart, not here — this widget is
    // only mounted once popularPackagesProvider already has items (see
    // HomeScreen), so there'd be nothing to trigger it on first build.
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayPackages = ref.watch(popularPackagesProvider).items;

    // Defensive: HomeScreen only mounts this widget once there are items,
    // but a realtime 'hidden' event (see PopularPackagesNotifier) can empty
    // the list out from under it while it's still on screen — collapse to
    // nothing rather than a stray spinner in that case.
    if (displayPackages.isEmpty) {
      return const SizedBox.shrink();
    }

    // Keep the auto-scroll timer in sync with the live item count.
    _autoScrollTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % displayPackages.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });

    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _pageController,
        itemCount: displayPackages.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (_, i) {
          final distance = (_currentPage - i).abs().toDouble().clamp(0.0, 1.0);
          return AnimatedScale(
            scale: 1.0 - (distance * 0.06),
            duration: const Duration(milliseconds: 300),
            child: AnimatedOpacity(
              opacity: 1.0 - (distance * 0.3),
              duration: const Duration(milliseconds: 300),
              child: PackageShowcaseCard(pkg: displayPackages[i]),
            ),
          );
        },
      ),
    );
  }
}
