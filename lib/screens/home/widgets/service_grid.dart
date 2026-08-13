import 'package:flutter/material.dart';

import '../../../core/icons/app_icons.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';

class ServiceItem {
  const ServiceItem(this.icon, this.label);
  final String icon;
  final String label;
}

const kServiceItems = [
  ServiceItem(AppIcons.serviceWashFold, 'Wash & Fold'),
  ServiceItem(AppIcons.serviceIroning, 'Ironing'),
  ServiceItem(AppIcons.serviceDryClean, 'Dry Clean'),
  ServiceItem(AppIcons.serviceCarpets, 'Carpets'),
  ServiceItem(AppIcons.serviceShoeCare, 'Shoe Care'),
  ServiceItem(AppIcons.serviceCurtains, 'Curtains'),
  ServiceItem(AppIcons.serviceLeather, 'Leather & Suede'),
  ServiceItem(AppIcons.serviceBedding, 'Duvets & Bedding'),
  ServiceItem(AppIcons.serviceDelicates, 'Delicates'),
  ServiceItem(AppIcons.serviceSuits, 'Suits & Formal'),
  ServiceItem(AppIcons.serviceStainRemoval, 'Stain Removal'),
  ServiceItem(AppIcons.servicePillows, 'Pillows & Cushions'),
];

const _kTileWidth = 80.0;
const _kGridHeight = 132.0;

/// The service icon row on Home. Every entry in [kServiceItems] is reachable
/// by swiping horizontally — there's no "see all" toggle and no visible
/// scrollbar affordance, so it reads as one continuous strip of cards.
class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kGridHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: kServiceItems.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(
            width: _kTileWidth,
            child: _ServiceTile(item: kServiceItems[i], onTap: onTap),
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.item, required this.onTap});

  final ServiceItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: AppIcon(item.icon, size: 26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
