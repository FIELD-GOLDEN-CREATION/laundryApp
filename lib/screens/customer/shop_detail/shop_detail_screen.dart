import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../data/mock_data.dart';
import '../../../models/menu_item.dart';
import '../../../models/service_package.dart';
import '../../../models/shop.dart';
import '../../../state/cart_state.dart';
import '../../../state/fulfillment_state.dart';
import '../../../state/profile_state.dart';
import '../../../state/vendor_packages_state.dart';
import '../../../state/vendor_profile_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/basket_shop_guard.dart';
import '../../../widgets/primary_cta_bar.dart';
import '../../../widgets/remote_image.dart';
import '../../../widgets/round_back_button.dart';
import '../../../widgets/shop_photo_slideshow.dart';
import 'widgets/package_card.dart';

/// (background, foreground) pairs cycled across a shop's feature badges.
const _kBadgeColors = [
  (AppColors.tealMuted, AppColors.teal),
  (AppColors.amberLight, AppColors.amber),
  (AppColors.creamDark, AppColors.muted),
];

const _kTabLabels = ['About', 'Packages', 'Price list'];

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({super.key, required this.shop});

  final Shop shop;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final qty = ref.watch(cartProvider);
    final fav = ref.watch(profileProvider.select((s) => s.fav));
    // Service and package lines live outside `kMenuItems`, so every total on
    // this screen has to be priced with them the way Cart/Checkout do.
    final extraItems = ref.watch(fulfillmentProvider).extraItems.values.toList();

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

    // Same trace for the catalogue: the vendor's own packages come from what
    // they authored on the Vendor Catalog screen, every other shop from seed.
    final packages = isVendorShop ? activeVendorPackages(ref.watch(vendorPackagesProvider)) : packagesFor(shop);

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
                  const SizedBox(height: 20),
                  _ShopTabBar(
                    labels: _kTabLabels,
                    index: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 18),
                  if (_tab == 0)
                    Text(
                      displayDescription,
                      style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.6),
                    )
                  else if (_tab == 1)
                    packages.isEmpty
                        ? const _EmptyTabMessage(text: 'This shop hasn\'t listed any packages yet.')
                        : Column(
                            children: [
                              Text(
                                'Bundles that cover a whole load — pick one instead of '
                                'counting garments one by one.',
                                style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.45),
                              ),
                              const SizedBox(height: 12),
                              for (final package in packages) ...[
                                PackageCard(
                                  package: package,
                                  inBasket: (qty[package.cartKey(shop.slotId)] ?? 0) > 0,
                                  onSelect: () => _selectPackage(context, package, displayName),
                                ),
                                if (package != packages.last) const SizedBox(height: 10),
                              ],
                            ],
                          )
                  else
                    Column(
                      children: [
                        for (final item in kMenuItems) ...[
                          _MenuRow(
                            item: item,
                            checked: (qty[item.key] ?? 0) > 0,
                            onToggle: () => _toggleMenuItem(context, item, displayName),
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
        hint: formatMoney(cartSubtotal(qty, extraItems)),
        onPressed: () => context.push('/cart'),
      ),
    );
  }

  /// Adds a package as a single basket line. It rides the same
  /// `extraItems` seam service items use, so Cart, Schedule, Checkout and
  /// the placed order's lines all price it without any further plumbing.
  Future<void> _selectPackage(BuildContext context, ServicePackage package, String shopName) async {
    final key = package.cartKey(widget.shop.slotId);

    // Already a line — send them to the basket rather than quietly stacking
    // a second copy of a bundle they think they bought once.
    if ((ref.read(cartProvider)[key] ?? 0) > 0) {
      context.push('/cart');
      return;
    }

    if (!await ensureBasketShop(context, ref, shopName)) return;
    if (!context.mounted) return;

    ref.read(fulfillmentProvider.notifier).addServiceItem(
      MenuItem(
        key: key,
        name: package.name,
        unit: package.cartSubtitle,
        initial: package.initial,
        price: package.priceTzs,
      ),
    );
    ref.read(cartProvider.notifier).setQty(key, 1);
  }

  /// Ticking a service's checkbox adds a single unit to the basket; ticking
  /// it off drops the line entirely. Quantity beyond that is adjusted on
  /// the basket page's own +/- steppers, not here.
  Future<void> _toggleMenuItem(BuildContext context, MenuItem item, String shopName) async {
    final currentQty = ref.read(cartProvider)[item.key] ?? 0;
    if (currentQty > 0) {
      ref.read(cartProvider.notifier).setQty(item.key, -currentQty);
      return;
    }

    if (!await ensureBasketShop(context, ref, shopName)) return;
    if (!context.mounted) return;
    ref.read(cartProvider.notifier).setQty(item.key, 1);
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

/// Pill-shaped segmented control switching between the About / Packages /
/// Price list sections, matching the Orders screen's Active/Completed tabs.
class _ShopTabBar extends StatelessWidget {
  const _ShopTabBar({required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _ShopTabButton(label: labels[i], active: index == i, onTap: () => onChanged(i)),
            ),
        ],
      ),
    );
  }
}

class _ShopTabButton extends StatelessWidget {
  const _ShopTabButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: active ? AppColors.teal : AppColors.muted),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared "nothing here yet" line for a tab with no content — currently
/// only the Packages tab can be empty (a shop with no bundles authored).
class _EmptyTabMessage extends StatelessWidget {
  const _EmptyTabMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.5),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.checked, required this.onToggle});

  final MenuItem item;

  /// Whether this service already has a line in the basket.
  final bool checked;

  final VoidCallback onToggle;

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
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _ItemCheckbox(checked: checked),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same rounded-square checkbox styling as the vendor order detail screen's
/// damage checklist, reused here so the tick affordance reads consistently
/// across the app.
class _ItemCheckbox extends StatelessWidget {
  const _ItemCheckbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? AppColors.teal : Colors.transparent,
        border: Border.all(color: checked ? AppColors.teal : AppColors.creamDark, width: 2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: checked ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
    );
  }
}
