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

  Color get _accent => switch (pkg.kind) {
    PackageKind.weight => AppColors.teal,
    PackageKind.itemCount => AppColors.amber,
    PackageKind.household => const Color(0xFF1F5ECC),
  };

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
    if (pkg.priceNegotiable) return 'Negotiable';
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
        priceLabel: '${_priceLabel()} ${pkg.priceNegotiable ? '' : pkg.priceUnit}'.trim(),
        detail: _scopeLabel,
      ),
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp.')),
      );
    }
  }

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
    // Already active in this vendor's basket — send them to cart instead of
    // re-adding, which would otherwise double up the same package items in
    // the cart. Other packages already active for this shop are left alone,
    // since a customer can stack more than one.
    final alreadyActive = ref.read(basketsProvider)[pkg.shopId]?.activePackages.containsKey(pkg.id) ?? false;
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
        color: AppColors.clientSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.clientBorder(context)),
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
          // ── Photo area (image behind, like the basket card) ─────────
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RemoteImage(url: pkg.displayImage, fallback: pkg.name),
                  // Dark veil so pills stay readable on any photo.
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                        stops: const [0.0, 0.5, 1.0],
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
                          color: AppColors.clientPillAmber(context),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pkg.tag,
                          style: AppText.sans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.clientAmberText(context),
                          ),
                        ),
                      ),
                    ),
                  // WhatsApp (top-right)
                  if (shopPhone.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _WhatsAppButton(
                        onTap: () => _chatWhatsApp(context, shopPhone),
                      ),
                    ),
                  // Kind badge (bottom-right)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
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
                  // Scope (bottom-left)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _scopeLabel,
                        style: AppText.sans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
                    style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pkg.tagline,
                    style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
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
                                color: AppColors.clientPillTeal(context),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'Save $savings%',
                                style: AppText.sans(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.clientTealText(context)),
                              ),
                            ),
                          if (savings != null) const SizedBox(height: 3),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _priceLabel(),
                                style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.clientTealText(context)),
                              ),
                              if (!pkg.priceNegotiable) ...[
                                const SizedBox(width: 2),
                                Text(
                                  pkg.priceUnit,
                                  style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                                ),
                              ],
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
