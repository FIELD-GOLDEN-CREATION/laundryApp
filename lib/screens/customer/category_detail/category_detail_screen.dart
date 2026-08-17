import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/mock_data.dart';
import '../../../models/laundry_category.dart';
import '../../../models/shop.dart';
import '../../../state/client_preferences_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/currency.dart';
import '../../../widgets/remote_image.dart';
import '../../../widgets/round_back_button.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.category});

  final LaundryCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(clientPreferencesProvider).language;
    final dark = AppColors.isClientDark(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroSection(category: category, language: language, dark: dark),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language == 'Swahili' ? category.nameSwahili : category.name,
                    style: AppText.serif(fontSize: 27),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    language == 'Swahili' ? category.description : category.description,
                    style: AppText.sans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.clientSecondaryText(context),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: '${category.items.length} ${language == 'Swahili' ? 'bidhaa' : 'items'}',
                        dark: dark,
                      ),
                      const SizedBox(width: 10),
                      _InfoChip(
                        icon: Icons.local_shipping_outlined,
                        label: language == 'Swahili' ? 'Utoaji unapatikana' : 'Delivery available',
                        dark: dark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    language == 'Swahili' ? 'ORODHA YA BEI' : 'PRICE LIST',
                    style: AppText.eyebrow(),
                  ),
                  const SizedBox(height: 12),
                  ...category.items.map((item) {
                    final shopWithItem = _findCheapestShopForItem(item.id);
                    final vendorPrice = shopWithItem?.$2 ?? item.priceTzs;
                    final vendorShop = shopWithItem?.$1;
                    return _CategoryItemCard(
                      item: item,
                      language: language,
                      dark: dark,
                      vendorPrice: vendorPrice,
                      shopName: vendorShop?.name,
                      onTap: vendorShop != null
                          ? () => context.push('/detail', extra: vendorShop)
                          : () {},
                    );
                  }),
                  const SizedBox(height: 20),
                  _DeliveryInfoBanner(dark: dark, language: language),
                  const SizedBox(height: 20),
                  _FindShopsButton(
                    onPressed: () => context.go('/search'),
                    language: language,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns (Shop, price) for the cheapest shop that offers this item, or null.
(Shop, double)? _findCheapestShopForItem(String itemId) {
  (Shop, double)? cheapest;
  for (final shop in kShops) {
    final menuItem = kMenuItems.where((m) => m.key == itemId).firstOrNull;
    if (menuItem != null) {
      if (cheapest == null || menuItem.price < cheapest.$2) {
        cheapest = (shop, menuItem.price);
      }
    }
    // Map category item IDs to menu items
    final mappedKey = _itemToMenuKey(itemId);
    if (mappedKey != null) {
      final mappedItem = kMenuItems.where((m) => m.key == mappedKey).firstOrNull;
      if (mappedItem != null) {
        if (cheapest == null || mappedItem.price < cheapest.$2) {
          cheapest = (shop, mappedItem.price);
        }
      }
    }
  }
  // Return first shop as fallback if no match found
  return cheapest ?? (kShops.first, kMenuItems.first.price);
}

String? _itemToMenuKey(String itemId) {
  const mapping = {
    'tshirt-polo': 'shirt',
    'casual-shirt': 'shirt',
    'trousers-jeans': 'trouser',
    'shorts-skirt': 'shirt',
    'underwear-socks': 'shirt',
    'suit-2piece': 'dress',
    'suit-3piece': 'dress',
    'suit-jacket': 'dress',
    'heavy-coat': 'dress',
    'sweater-cardigan': 'dress',
    'evening-gown': 'dress',
    'wedding-dress': 'dress',
    'sneakers': 'shirt',
    'leather-shoes': 'dress',
    'suede-shoes': 'dress',
    'backpack-duffel': 'shirt',
    'handbag-leather': 'dress',
    'blanket-single': 'bed',
    'blanket-duvet': 'bed',
    'bedsheet': 'bed',
    'duvet-cover': 'bed',
    'pillow-cushion': 'bed',
    'curtains': 'bed',
    'bulk-wash-kg': 'shirt',
    'ironing-only': 'shirt',
  };
  return mapping[itemId];
}

class _HeroSection extends StatefulWidget {
  const _HeroSection({
    required this.category,
    required this.language,
    required this.dark,
  });

  final LaundryCategory category;
  final String language;
  final bool dark;

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  final _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.category.items;
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => RemoteImage(
              url: items[i].imageUrl,
              fallback: items[i].name,
              fit: BoxFit.cover,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0),
                  widget.dark
                      ? const Color(0xFF080D12).withValues(alpha: 0.9)
                      : AppColors.cream.withValues(alpha: 0.9),
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
                  if (items.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${items.length}',
                        style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (items.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < items.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentIndex ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: i == _currentIndex ? 0.95 : 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.dark,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.clientSurfaceRaised(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.clientBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.teal),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.clientText(context)),
          ),
        ],
      ),
    );
  }
}

class _CategoryItemCard extends StatelessWidget {
  const _CategoryItemCard({
    required this.item,
    required this.language,
    required this.dark,
    required this.onTap,
    this.vendorPrice,
    this.shopName,
  });

  final LaundryItem item;
  final String language;
  final bool dark;
  final VoidCallback onTap;
  final double? vendorPrice;
  final String? shopName;

  @override
  Widget build(BuildContext context) {
    final displayPrice = vendorPrice ?? item.priceTzs;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.clientBorder(context)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: RemoteImage(
                      url: item.imageUrl,
                      fallback: item.name,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language == 'Swahili' ? item.nameSwahili : item.name,
                        style: AppText.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.clientText(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: AppText.sans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.clientSecondaryText(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.tealMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.unit,
                              style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal),
                            ),
                          ),
                          if (shopName != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.amberLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'from $shopName',
                                style: AppText.sans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.amber),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatTzs(displayPrice),
                      style: AppText.sans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.clientSecondaryText(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryInfoBanner extends StatelessWidget {
  const _DeliveryInfoBanner({required this.dark, required this.language});

  final bool dark;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tealMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delivery_dining, color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language == 'Swahili' ? 'Utoaji na Uchukuaji' : 'Pickup & Delivery',
                  style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal),
                ),
                const SizedBox(height: 4),
                Text(
                  language == 'Swahili'
                      ? 'Dereva wetu atachukua na kuleta nguo zako'
                      : 'Our driver picks up and delivers your items',
                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FindShopsButton extends StatelessWidget {
  const _FindShopsButton({required this.onPressed, required this.language});

  final VoidCallback onPressed;
  final String language;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(
              language == 'Swahili' ? 'Tafuta Maduka' : 'Find Shops',
              style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
