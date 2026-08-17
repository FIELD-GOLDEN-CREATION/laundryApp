import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../widgets/remote_image.dart';
import '../../../widgets/shop_photo_slideshow.dart';
import 'widgets/package_card.dart';

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
    final extraItems = ref.watch(fulfillmentProvider).extraItems.values.toList();

    final isVendorShop = shop.slotId == kShops.first.slotId;
    final vendorProfile = ref.watch(vendorProfileProvider);
    final displayName = isVendorShop ? vendorProfile.shopTitle : shop.name;
    final displayDescription = isVendorShop ? vendorProfile.bio : shop.description;
    final displayHours = isVendorShop
        ? (vendorProfile.isOpen ? 'Open till ${vendorProfile.closeTime}' : 'Closed now')
        : shop.hours;
    final displayHoursColor = isVendorShop && !vendorProfile.isOpen ? AppColors.danger : AppColors.teal;

    final packages = isVendorShop ? activeVendorPackages(ref.watch(vendorPackagesProvider)) : packagesFor(shop);

    return Scaffold(
      backgroundColor: AppColors.clientSurface(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 200),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppText.serif(fontSize: 28, color: AppColors.clientText(context)),
                      ),
                      const SizedBox(height: 10),
                      _InfoChips(
                        shop: shop,
                        displayHours: displayHours,
                        displayHoursColor: displayHoursColor,
                      ),
                      const SizedBox(height: 20),
                      if (shop.badges.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: shop.badges.map((badge) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.tealMuted,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge,
                              style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _DirectionButton(
                        onPressed: () => context.push('/direction', extra: shop),
                      ),
                      const SizedBox(height: 20),
                      _ShopTabBar(
                        labels: _kTabLabels,
                        index: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                      ),
                      const SizedBox(height: 18),
                      if (_tab == 0)
                        _AboutSection(
                          description: displayDescription,
                          shop: shop,
                          isVendorShop: isVendorShop,
                          vendorProfile: vendorProfile,
                        )
                      else if (_tab == 1)
                        packages.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'This shop hasn\'t listed any packages yet.',
                                  style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context), height: 1.5),
                                ),
                              )
                            : Column(
                                children: [
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
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _EdgedHeroImage(
              shop: shop,
              isVendorShop: isVendorShop,
              vendorProfile: vendorProfile,
              fav: fav,
              onFavToggle: () => ref.read(profileProvider.notifier).toggleFav(),
              onBack: () => context.pop(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        shop: shop,
        isVendorShop: isVendorShop,
        vendorProfile: vendorProfile,
        cartTotal: formatMoney(cartSubtotal(qty, extraItems)),
        onViewBasket: () => context.push('/cart'),
      ),
    );
  }

  Future<void> _selectPackage(BuildContext context, ServicePackage package, String shopName) async {
    final key = package.cartKey(widget.shop.slotId);
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

class _EdgedHeroImage extends StatelessWidget {
  const _EdgedHeroImage({
    required this.shop,
    required this.isVendorShop,
    required this.vendorProfile,
    required this.fav,
    required this.onFavToggle,
    required this.onBack,
  });

  final Shop shop;
  final bool isVendorShop;
  final dynamic vendorProfile;
  final bool fav;
  final VoidCallback onFavToggle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVendorShop && vendorProfile.shopPhotoLabels.isNotEmpty)
            ShopPhotoSlideshow(labels: vendorProfile.shopPhotoLabels)
          else
            RemoteImage(url: shop.imageUrl, fallback: 'Shop storefront photo', fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.15),
                ],
                stops: const [0, 0.5, 1],
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
                  _GlassButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: onBack,
                  ),
                  Row(
                    children: [
                      _GlassButton(
                        icon: fav ? Icons.favorite : Icons.favorite_border,
                        onTap: onFavToggle,
                        iconColor: fav ? AppColors.danger : null,
                      ),
                      const SizedBox(width: 10),
                      _GlassButton(
                        icon: Icons.share_outlined,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _BottomEdgeClipper(),
              child: Container(
                height: 20,
                color: AppColors.clientSurface(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 20);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 20);
    path.lineTo(size.width, 20);
    path.lineTo(0, 20);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Icon(icon, size: 20, color: iconColor ?? Colors.white),
          ),
        ),
      ),
    );
  }
}

class _InfoChips extends StatelessWidget {
  const _InfoChips({
    required this.shop,
    required this.displayHours,
    required this.displayHoursColor,
  });

  final Shop shop;
  final String displayHours;
  final Color displayHoursColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.star,
          text: shop.rating,
          color: AppColors.amber,
        ),
        const SizedBox(width: 8),
        _InfoChip(
          icon: Icons.reviews_outlined,
          text: '${shop.reviewCount} reviews',
          color: AppColors.clientSecondaryText(context),
        ),
        const SizedBox(width: 8),
        _InfoChip(
          icon: Icons.location_on_outlined,
          text: shop.distance,
          color: AppColors.clientSecondaryText(context),
        ),
        const SizedBox(width: 8),
        _InfoChip(
          icon: Icons.schedule,
          text: displayHours,
          color: displayHoursColor,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.clientSurfaceRaised(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.clientBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.clientText(context)),
          ),
        ],
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.clientBorder(context), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_outlined, size: 18, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                'Get Directions',
                style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.description,
    required this.shop,
    required this.isVendorShop,
    required this.vendorProfile,
  });

  final String description;
  final Shop shop;
  final bool isVendorShop;
  final dynamic vendorProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About ${shop.name}',
          style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context), height: 1.6),
        ),
        const SizedBox(height: 16),
        if (shop.services.isNotEmpty) ...[
          for (final service in shop.services)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: AppColors.teal),
                  const SizedBox(width: 10),
                  Text(
                    service,
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientText(context)),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 16),
        if (isVendorShop) ...[
          Row(
            children: [
              Icon(Icons.schedule_outlined, size: 16, color: AppColors.clientSecondaryText(context)),
              const SizedBox(width: 8),
              Text(
                vendorProfile.scheduleSummary,
                style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: AppColors.clientSecondaryText(context)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                shop.distance,
                style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShopTabBar extends StatelessWidget {
  const _ShopTabBar({required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.clientBorder(context),
        borderRadius: BorderRadius.circular(999),
      ),
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
      color: active ? AppColors.clientSurface(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: AppText.sans(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: active ? AppColors.teal : AppColors.clientSecondaryText(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.checked, required this.onToggle});

  final MenuItem item;
  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.clientSurfaceRaised(context),
        border: Border.all(color: AppColors.clientBorder(context)),
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
                Text(item.name, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                const SizedBox(height: 2),
                Text(
                  item.unit,
                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
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
        border: Border.all(color: checked ? AppColors.teal : AppColors.clientBorder(context), width: 2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: checked ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.shop,
    required this.isVendorShop,
    required this.vendorProfile,
    required this.cartTotal,
    required this.onViewBasket,
  });

  final Shop shop;
  final bool isVendorShop;
  final dynamic vendorProfile;
  final String cartTotal;
  final VoidCallback onViewBasket;

  @override
  Widget build(BuildContext context) {
    final displayName = isVendorShop ? vendorProfile.shopTitle : shop.name;
    final initials = displayName.split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border(
          top: BorderSide(color: AppColors.clientBorder(context)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.tealMuted,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
                  ),
                  Text(
                    cartTotal,
                    style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: Material(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onViewBasket,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: Text(
                        'View basket',
                        style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
