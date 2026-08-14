import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../data/mock_data.dart';
import '../../models/menu_item.dart';
import '../../models/shop.dart';
import '../../state/cart_state.dart';
import '../../state/profile_state.dart';
import '../../state/vendor_profile_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_cta_bar.dart';
import '../../widgets/remote_image.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/shop_photo_slideshow.dart';

/// (background, foreground) pairs cycled across a shop's feature badges.
const _kBadgeColors = [
  (AppColors.tealMuted, AppColors.teal),
  (AppColors.amberLight, AppColors.amber),
  (AppColors.creamDark, AppColors.muted),
];

class ShopDetailScreen extends ConsumerWidget {
  const ShopDetailScreen({super.key, required this.shop});

  final Shop shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider);
    final fav = ref.watch(profileProvider.select((s) => s.fav));

    // The vendor's own listing (`kShops.first`) mirrors whatever was last
    // saved on the Vendor Settings screen, so an edit there is immediately
    // visible here — the customer-facing half of that "trace".
    final isVendorShop = shop.slotId == kShops.first.slotId;
    final vendorProfile = ref.watch(vendorProfileProvider);
    final displayName = isVendorShop ? vendorProfile.shopTitle : shop.name;
    final displayDescription = isVendorShop ? vendorProfile.bio : shop.description;
    final displayHours = isVendorShop
        ? (vendorProfile.isOpen ? 'Open till ${vendorProfile.closeTime}' : 'Closed now')
        : shop.hours;
    final displayHoursColor = isVendorShop && !vendorProfile.isOpen ? AppColors.danger : AppColors.teal;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 270,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isVendorShop && vendorProfile.shopPhotoLabels.isNotEmpty)
                    ShopPhotoSlideshow(labels: vendorProfile.shopPhotoLabels)
                  else
                    RemoteImage(url: shop.imageUrl, fallback: 'Shop storefront photo'),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.teal.withValues(alpha: 0.45),
                          AppColors.teal.withValues(alpha: 0),
                          AppColors.cream.withValues(alpha: 0.9),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RoundBackButton(onPressed: () => context.pop()),
                          _CircleIconButton(
                            icon: fav ? AppIcons.heartFilled : AppIcons.heartOutline,
                            onTap: () => ref.read(profileProvider.notifier).toggleFav(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: AppText.serif(fontSize: 27)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Row(
                        children: [
                          const AppIcon(AppIcons.star, size: 12),
                          const SizedBox(width: 5),
                          Text(
                            shop.rating,
                            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.amber),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${shop.reviewCount})',
                            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Text(
                        shop.distance,
                        style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        displayHours,
                        style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: displayHoursColor),
                      ),
                    ],
                  ),
                  if (isVendorShop) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const AppIcon(AppIcons.clock, size: 13, color: AppColors.muted),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            vendorProfile.scheduleSummary,
                            style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < shop.badges.length; i++)
                        _Badge(label: shop.badges[i], bg: _kBadgeColors[i % _kBadgeColors.length].$1, fg: _kBadgeColors[i % _kBadgeColors.length].$2),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayDescription,
                    style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Text('Price list', style: AppText.serif(fontSize: 19)),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      for (final item in kMenuItems) ...[
                        _MenuRow(
                          item: item,
                          onAdd: () => ref.read(cartProvider.notifier).setQty(item.key, 1),
                        ),
                        if (item != kMenuItems.last) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PrimaryCtaBar(
        label: 'View basket',
        hint: formatMoney(cartSubtotal(qty)),
        onPressed: () => context.push('/cart'),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 42, height: 42, child: Center(child: AppIcon(icon, size: 19))),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onAdd});

  final MenuItem item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(13)),
            alignment: Alignment.center,
            child: Text(item.initial, style: AppText.serif(fontSize: 16, color: AppColors.teal)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  item.unit,
                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            formatMoney(item.price),
            style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal),
          ),
          const SizedBox(width: 4),
          Material(
            color: AppColors.teal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onAdd,
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Text(
                    '+',
                    style: AppText.sans(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
