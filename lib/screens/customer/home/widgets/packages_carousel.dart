import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/mock_data.dart';
import '../../../../models/service_package.dart';
import '../../../../models/user_role.dart';
import '../../../../state/auth_state.dart';
import '../../../../state/cart_state.dart';
import '../../../../state/fulfillment_state.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';

// Storyset Shopping illustrations — https://storyset.com/shopping
const _kPackageIllustrations = {
  'student-bag': 'https://stories.freepiklabs.com/storage/49900/Laundy-and-dry-cleaning-01.svg',
  'corporate-weekly': 'https://stories.freepiklabs.com/storage/4070/Credit-card-amico.svg',
  'bedding-refresh': 'https://stories.freepiklabs.com/storage/54558/Credit-card_Mesa-de-trabajo-1.svg',
  'family-monthly': 'https://stories.freepiklabs.com/storage/36117/553-In-no-time-doing-2_Artboard-1.svg',
  'family-bag': 'https://stories.freepiklabs.com/storage/54881/Ecommerce-web-page-01.svg',
  'suit-care': 'https://stories.freepiklabs.com/storage/54544/Credit-card-pana-01.svg',
};

class PackagesCarousel extends ConsumerStatefulWidget {
  const PackagesCarousel({super.key});

  @override
  ConsumerState<PackagesCarousel> createState() => _PackagesCarouselState();
}

class _PackagesCarouselState extends ConsumerState<PackagesCarousel> {
  late final PageController _pageController;
  late Timer _autoScrollTimer;
  int _currentPage = 0;

  static final _displayPackages = [
    kServicePackages[0], // Student Bag (weight)
    kServicePackages[1], // Corporate Weekly (itemCount)
    kServicePackages[2], // Bedding Refresh (household)
    kServicePackages[3], // Family Monthly (subscription)
    kServicePackages[4], // Family Bag (weight)
    kServicePackages[5], // Suit Care Duo (itemCount)
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _displayPackages.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _displayPackages.length,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemBuilder: (_, i) {
          final distance = (_currentPage - i).abs().toDouble().clamp(0.0, 1.0);
          return AnimatedScale(
            scale: 1.0 - (distance * 0.06),
            duration: const Duration(milliseconds: 300),
            child: AnimatedOpacity(
              opacity: 1.0 - (distance * 0.3),
              duration: const Duration(milliseconds: 300),
              child: _PackageCard(pkg: _displayPackages[i]),
            ),
          );
        },
      ),
    );
  }
}

class _PackageCard extends ConsumerWidget {
  const _PackageCard({required this.pkg});
  final ServicePackage pkg;

  Color get _accent => switch (pkg.kind) {
    PackageKind.weight => AppColors.teal,
    PackageKind.itemCount => AppColors.amber,
    PackageKind.household => const Color(0xFF1F5ECC),
    PackageKind.subscription => AppColors.teal,
  };

  Color get _bgTint => switch (pkg.kind) {
    PackageKind.weight => const Color(0xFFF0FAF8),
    PackageKind.itemCount => const Color(0xFFFEF8EE),
    PackageKind.household => const Color(0xFFEEF4FD),
    PackageKind.subscription => const Color(0xFFF0FAF8),
  };

  String get _kindLabel => switch (pkg.kind) {
    PackageKind.weight => 'Weight',
    PackageKind.itemCount => 'Item',
    PackageKind.household => 'Household',
    PackageKind.subscription => 'Monthly',
  };

  void _onTap(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    if (auth.role == UserRole.guest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in as a customer to add packages to your basket.')),
      );
      return;
    }
    if (pkg.packageItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This package has no items configured yet.')),
      );
      return;
    }
    final cart = ref.read(cartProvider.notifier);
    final cartPkg = ref.read(cartPackageProvider.notifier);
    final fulfillment = ref.read(fulfillmentProvider.notifier);
    fulfillment.setShop('Marina Fresh Laundry');
    cartPkg.addPackage(pkg, cart);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${pkg.name} added to basket!'),
        action: SnackBarAction(label: 'View basket', textColor: AppColors.teal, onPressed: () => context.push('/cart')),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savings = pkg.savingsPercent;
    final illustrationUrl = _kPackageIllustrations[pkg.id];

    return GestureDetector(
      onTap: () => _onTap(context, ref),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.creamDark),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Illustration area ──────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _bgTint,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  // Decorative circle
                  Positioned(
                    right: -12,
                    top: -12,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _accent.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  // Illustration
                  if (illustrationUrl != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.network(
                          illustrationUrl,
                          fit: BoxFit.contain,
                          placeholderBuilder: (_) => Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 28,
                              color: _accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Tag pill (top-left)
                  if (pkg.tag.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.amberLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pkg.tag,
                          style: AppText.sans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.amber,
                          ),
                        ),
                      ),
                    ),
                  // Kind badge (bottom-right)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _accent.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        _kindLabel,
                        style: AppText.sans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Info area ──────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.name,
                    style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pkg.tagline,
                    style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (savings != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.tealMuted,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'Save $savings%',
                                style: AppText.sans(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.teal),
                              ),
                            ),
                          if (savings != null) const SizedBox(height: 3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'TZS ${pkg.priceTzs.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.teal),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                pkg.priceUnit,
                                style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
