import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/menu_item.dart';
import '../../../models/service_package.dart';
import '../../../models/shop.dart';
import '../../../state/catalog_state.dart';
import '../../../state/profile_state.dart';
import '../../../state/vendor_basket.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/cart_math.dart';
import '../../../widgets/remote_image.dart';
import '../../../widgets/shop_location_label.dart';
import 'widgets/package_card.dart';

const _kTabLabels = ['About', 'Packages', 'Price list'];

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({super.key, required this.shop, this.initialTab = 0});

  final Shop shop;

  /// Tab to open on ('About', 'Packages', 'Price list'), e.g. 1 to land
  /// straight on Packages when arriving from a package tap elsewhere.
  final int initialTab;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  late int _tab = widget.initialTab;
  bool _catalogRegistered = false;

  @override
  void initState() {
    super.initState();
    // Both providers are plain FutureProvider.family (not autoDispose), so
    // once fetched they stay cached in memory for the rest of the app
    // session — a vendor's catalog edit would never appear on a shop page
    // the customer had already opened without this explicit refetch.
    Future.microtask(() {
      ref.invalidate(shopDetailProvider(widget.shop.listSlotId));
      ref.invalidate(shopPackagesProvider(widget.shop.slotId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final basket = ref.watch(basketsProvider.select((m) => m[shop.slotId])) ?? VendorBasket.empty(shop.slotId);
    final qty = basket.qty;
    final fav = ref.watch(profileProvider.select((s) => s.fav));

    final displayName = shop.name;
    final displayDescription = shop.description;
    final displayHours = shop.isOpenNow ? (shop.hours.isNotEmpty ? shop.hours : 'Open') : 'Closed now';
    final displayHoursColor = shop.isOpenNow ? AppColors.teal : AppColors.danger;

    final detailAsync = ref.watch(shopDetailProvider(shop.listSlotId));
    final packagesAsync = ref.watch(shopPackagesProvider(shop.slotId));
    final loading = detailAsync.isLoading || packagesAsync.isLoading;
    final packages = packagesAsync.asData?.value ?? const <ServicePackage>[];
    final priceList = detailAsync.asData?.value ?? const <MenuItem>[];

    // Register this shop's price list into ITS OWN basket entry — every
    // vendor keeps a separate `VendorBasket`, so there's no other vendor's
    // state this could ever collide with or need to defer to.
    if (!_catalogRegistered && priceList.isNotEmpty) {
      _catalogRegistered = true;
      Future.microtask(() => ref.read(basketsProvider.notifier).setShopCatalog(
            shop.slotId,
            shopName: shop.name,
            shopSlug: shop.listSlotId,
            items: priceList,
          ));
    }

    final pricedItems = basket.pricedItems;

    return Scaffold(
      backgroundColor: AppColors.clientSurface(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EdgedHeroImage(
              shop: shop,
              fav: fav,
              onFavToggle: () => ref.read(profileProvider.notifier).toggleFav(),
              onBack: () => context.pop(),
            ),
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
                    )
                  else if (_tab == 1)
                    loading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : packages.isEmpty
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
                                      onSelect: () => _selectPackage(context, package),
                                    ),
                                    if (package != packages.last) const SizedBox(height: 10),
                                  ],
                                ],
                              )
                  else
                    loading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : priceList.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No price list available yet.',
                                  style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context), height: 1.5),
                                ),
                              )
                            : Column(
                                children: [
                                  for (final item in priceList) ...[
                                    _MenuRow(
                                      item: item,
                                      checked: (qty[item.key] ?? 0) > 0,
                                      onToggle: () => _toggleMenuItem(item),
                                    ),
                                    if (item != priceList.last) const SizedBox(height: 10),
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
      bottomNavigationBar: _BottomBar(
        shopName: displayName,
        imageUrl: shop.imageUrl,
        cartTotal: formatMoney(cartSubtotal(qty, [], pricedItems)),
        onViewBasket: () => context.push('/cart', extra: shop.slotId),
      ),
    );
  }

  void _selectPackage(BuildContext context, ServicePackage package) {
    final shopId = widget.shop.slotId;
    final key = package.cartKey(shopId);
    final notifier = ref.read(basketsProvider.notifier);
    if ((ref.read(basketsProvider)[shopId]?.qty[key] ?? 0) > 0) {
      context.push('/cart', extra: shopId);
      return;
    }
    notifier.addPackage(shopId, package);
  }

  void _toggleMenuItem(MenuItem item) {
    final shopId = widget.shop.slotId;
    final notifier = ref.read(basketsProvider.notifier);
    final currentQty = ref.read(basketsProvider)[shopId]?.qty[item.key] ?? 0;
    if (currentQty > 0) {
      notifier.setQty(shopId, item.key, -currentQty);
      return;
    }
    notifier.setQty(shopId, item.key, 1);
  }
}

/// Shows the shop's uploaded photo gallery as an auto-advancing slideshow —
/// 4s per photo, matching the vendor Settings screen's own copy — falling
/// back to the single storefront [Shop.imageUrl] when no gallery exists.
class _EdgedHeroImage extends StatefulWidget {
  const _EdgedHeroImage({
    required this.shop,
    required this.fav,
    required this.onFavToggle,
    required this.onBack,
  });

  final Shop shop;
  final bool fav;
  final VoidCallback onFavToggle;
  final VoidCallback onBack;

  @override
  State<_EdgedHeroImage> createState() => _EdgedHeroImageState();
}

class _EdgedHeroImageState extends State<_EdgedHeroImage> {
  Timer? _timer;
  int _index = 0;

  List<String> get _slides {
    final photos = widget.shop.photos;
    if (photos.isNotEmpty) return photos;
    return [widget.shop.imageUrl];
  }

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant _EdgedHeroImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shop.listSlotId != widget.shop.listSlotId) {
      _index = 0;
      _restartTimer();
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_slides.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _slides.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    final url = slides[_index.clamp(0, slides.length - 1)];
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: RemoteImage(key: ValueKey(url), url: url, fallback: widget.shop.name, fit: BoxFit.cover),
          ),
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
                    onTap: widget.onBack,
                  ),
                  Row(
                    children: [
                      _GlassButton(
                        icon: widget.fav ? Icons.favorite : Icons.favorite_border,
                        onTap: widget.onFavToggle,
                        iconColor: widget.fav ? AppColors.danger : null,
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
  });

  final String description;
  final Shop shop;

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
        if (shop.hours.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.schedule_outlined, size: 16, color: AppColors.clientSecondaryText(context)),
              const SizedBox(width: 8),
              Text(
                shop.hours,
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
              child: shop.distance.isNotEmpty
                  ? Text(
                      '${shop.distance} km away',
                      style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                    )
                  : ShopLocationLabel(
                      shop: shop,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 40,
              height: 40,
              child: RemoteImage(
                url: item.imageUrl,
                fallback: item.initial,
                borderRadius: 13,
              ),
            ),
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
    required this.shopName,
    required this.imageUrl,
    required this.cartTotal,
    required this.onViewBasket,
  });

  final String shopName;
  final String imageUrl;
  final String cartTotal;
  final VoidCallback onViewBasket;

  @override
  Widget build(BuildContext context) {
    final initials = shopName
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();

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
                    shopName,
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
