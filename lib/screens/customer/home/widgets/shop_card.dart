import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../models/shop.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../widgets/remote_image.dart';

/// The horizontal-scroll shop card used in Home's "Nearby shops" section.
class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, required this.onTap});

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 208,
      child: Material(
         color: AppColors.clientSurface(context),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 104,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RemoteImage(url: shop.imageUrl, fallback: 'Shop photo'),                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.slate.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(AppIcons.star, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              shop.rating,
                              style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
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
                       style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shop.meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                       style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            shop.price,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.teal),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amberLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            shop.badge,
                            style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.amber),
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
                    Text(
                      shop.meta,
                       style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                    ),
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
