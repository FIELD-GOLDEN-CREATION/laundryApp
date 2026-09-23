import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../models/service_package.dart';
import '../../../../models/user_role.dart';
import '../../../../state/auth_state.dart';
import '../../../../state/catalog_state.dart';
import '../../../../state/vendor_basket.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../utils/contact_launcher.dart';
import '../../../../widgets/remote_image.dart';

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
              child: _PackageCard(pkg: displayPackages[i]),
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

  String get _kindLabel => switch (pkg.kind) {
    PackageKind.weight => 'Weight',
    PackageKind.itemCount => 'Item',
    PackageKind.household => 'Cleaning',
  };

  /// One-line scope summary shown under the tagline.
  String get _scopeLabel {
    switch (pkg.kind) {
      case PackageKind.weight:
        final kg = pkg.weightKg;
        return kg != null
            ? 'Up to ${kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1)} kg'
            : 'By weight';
      case PackageKind.itemCount:
        if (pkg.packageItems.isEmpty) return 'By items';
        final n = pkg.packageItems.fold(0, (a, e) => a + e.qty);
        return '$n items included';
      case PackageKind.household:
        final parts = [
          if (pkg.rooms != null)
            '${pkg.rooms} room${pkg.rooms == 1 ? '' : 's'}',
          if (pkg.gardenYard) 'Garden',
        ];
        return parts.isEmpty ? 'House cleaning' : parts.join(' · ');
    }
  }

  String _priceLabel() {
    if (pkg.isAskPrice) return 'Ask for price';
    return 'TZS ${pkg.priceTzs.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  /// Vendor phone for the WhatsApp enquiry button (hidden without one).
  String _shopPhone(WidgetRef ref) {
    try {
      final shops = ref.watch(shopsProvider).items;
      for (final s in shops) {
        if (s.slotId == pkg.shopId || s.listSlotId == pkg.shopId) {
          return s.phone;
        }
      }
    } catch (_) {}
    return '';
  }

  Future<void> _chatWhatsApp(BuildContext context, String phone) async {
    final ok = await launchWhatsAppChat(
      phone,
      message: packageWhatsAppMessage(
        shopName: pkg.shopName.isEmpty ? 'there' : pkg.shopName,
        packageName: pkg.name,
        priceLabel: pkg.isAskPrice
            ? 'Ask for price'
            : '${_priceLabel()} ${pkg.priceUnit}'.trim(),
        detail: _scopeLabel,
      ),
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  void _onTap(BuildContext context, WidgetRef ref) {
    // Ask-for-price packages go straight to WhatsApp instead of the basket.
    if (pkg.isAskPrice) {
      final phone = _shopPhone(ref);
      if (phone.isNotEmpty) {
        _chatWhatsApp(context, phone);
        return;
      }
    }
    final auth = ref.read(authProvider);
    if (auth.role == UserRole.guest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log in as a customer to add packages to your basket.'),
        ),
      );
      return;
    }
    if (pkg.packageItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This package has no items configured yet.'),
        ),
      );
      return;
    }
    // Already active in this vendor's basket — send them to cart instead of
    // re-adding, which would otherwise double up the same package items in
    // the cart. Other packages already active for this shop are left alone,
    // since a customer can stack more than one.
    final alreadyActive =
        ref
            .read(basketsProvider)[pkg.shopId]
            ?.activePackages
            .containsKey(pkg.id) ??
        false;
    if (!alreadyActive) {
      ref.read(basketsProvider.notifier).addPackage(pkg.shopId, pkg);
    }
    context.push('/cart', extra: pkg.shopId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savings = pkg.savingsPercent;
    final shopPhone = _shopPhone(ref);

    return GestureDetector(
      onTap: () => _onTap(context, ref),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo behind everything, like the create-basket card.
            RemoteImage(url: pkg.displayImage, fallback: pkg.name),
            // Black → transparent veil (left) + bottom shade for text.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.06),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const [0.45, 1.0],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _kindLabel.toUpperCase(),
                          style: AppText.sans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (pkg.isAskPrice) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'NEGOTIABLE',
                            style: AppText.sans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (pkg.tag.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            pkg.tag,
                            style: AppText.sans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (shopPhone.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _WhatsAppButton(
                          onTap: () => _chatWhatsApp(context, shopPhone),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  Text(
                    pkg.name,
                    style: AppText.serif(fontSize: 21, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _scopeLabel,
                    style: AppText.sans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Bottom strip: price + select affordance.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.clientSurface(
                        context,
                      ).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _priceLabel(),
                                style: AppText.sans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.clientText(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (savings != null)
                                Text(
                                  'Save $savings%',
                                  style: AppText.sans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.clientTealText(context),
                                  ),
                                ),
                              if (savings == null &&
                                  (pkg.tagline.isNotEmpty ||
                                      pkg.isAskPrice))
                                Text(
                                  pkg.isAskPrice && pkg.tagline.isEmpty
                                      ? 'Tap to chat on WhatsApp'
                                      : pkg.tagline,
                                  style: AppText.sans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.clientSecondaryText(
                                      context,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: pkg.isAskPrice
                                ? const Color(0xFF25D366)
                                : AppColors.teal,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            pkg.isAskPrice
                                ? Icons.chat_rounded
                                : Icons.chevron_right_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round WhatsApp button overlaid on package photos.
class _WhatsAppButton extends StatelessWidget {
  const _WhatsAppButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF25D366),
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.chat_rounded, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}
