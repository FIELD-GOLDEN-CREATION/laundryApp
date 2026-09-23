import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../models/shop.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../widgets/remote_image.dart';
import '../../../../widgets/shop_location_label.dart';

/// The horizontal-scroll shop card used in Home's "Nearby shops" section.
class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, required this.onTap});

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 216,
      child: Material(
        color: AppColors.clientSurface(context),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.clientBorder(context)),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 124,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RemoteImage(
                        url: shop.imageUrl,
                        fallback: 'Shop photo',
                      ),
                      // Bottom veil so the overlaid pills read on any photo.
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
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon(AppIcons.star, size: 11),
                              const SizedBox(width: 4),
                              Text(
                                shop.rating,
                                style: AppText.sans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: shop.isOpenNow
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFFF87171),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                shop.isOpenNow ? 'Open' : 'Closed',
                                style: AppText.sans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (shop.distanceKm >= 0)
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppIcon(
                                  AppIcons.locationPin,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  shop.distance,
                                  style: AppText.sans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.clientText(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      ShopLocationLabel(
                        shop: shop,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.clientSecondaryText(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              shop.price,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.clientTealText(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.clientPillAmber(context),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              shop.badge,
                              style: AppText.sans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.clientAmberText(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The full-width list-row variant used on Search.
class ShopListTile extends StatelessWidget {
  const ShopListTile({super.key, required this.shop, required this.onTap});

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
       color: AppColors.clientSurface(context),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
             border: Border.all(color: AppColors.clientBorder(context)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 86,
                height: 86,
                child: RemoteImage(url: shop.imageUrl, fallback: 'Shop', borderRadius: 16),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                    child: Text(shop.name, style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(AppIcons.star, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              shop.rating,
                              style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.amber),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ShopLocationLabel(
                            shop: shop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                          ),
                        ),
                        if (shop.distanceKm >= 0) ...[
                          const SizedBox(width: 6),
                          const AppIcon(AppIcons.locationPin, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            shop.distance,
                            style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal),
                          ),
                        ],
                      ],
                    ),
                    if (shop.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        shop.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tealMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            shop.badge,
                            style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                             color: AppColors.clientSurfaceRaised(context),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            shop.price,
                             style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.clientSecondaryText(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
