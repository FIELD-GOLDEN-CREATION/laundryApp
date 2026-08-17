import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../state/client_preferences_state.dart';

class ServiceItem {
  const ServiceItem(this.icon, this.label, this.swahili);
  final String icon;
  final String label;
  final String swahili;
}

const kServiceItems = [
  ServiceItem(AppIcons.serviceWashFold, 'Wash & Fold', 'Osha na kunja'),
  ServiceItem(AppIcons.serviceIroning, 'Ironing', 'Kupiga pasi'),
  ServiceItem(AppIcons.serviceDryClean, 'Dry Clean', 'Usafishaji mkavu'),
  ServiceItem(AppIcons.serviceCarpets, 'Carpets', 'Mazulia'),
  ServiceItem(AppIcons.serviceShoeCare, 'Shoe Care', 'Utunzaji wa viatu'),
  ServiceItem(AppIcons.serviceCurtains, 'Curtains', 'Mapazia'),
  ServiceItem(AppIcons.serviceLeather, 'Leather & Suede', 'Ngozi na suede'),
  ServiceItem(AppIcons.serviceBedding, 'Duvets & Bedding', 'Mashuka na duvet'),
  ServiceItem(AppIcons.serviceDelicates, 'Delicates', 'Nguo nyeti'),
  ServiceItem(AppIcons.serviceSuits, 'Suits & Formal', 'Suti na rasmi'),
  ServiceItem(AppIcons.serviceStainRemoval, 'Stain Removal', 'Kuondoa madoa'),
  ServiceItem(AppIcons.servicePillows, 'Pillows & Cushions', 'Mito na matakia'),
];

const _kTileWidth = 80.0;
const _kGridHeight = 132.0;

/// The service icon row on Home. Every entry in [kServiceItems] is reachable
/// by swiping horizontally — there's no "see all" toggle and no visible
/// scrollbar affordance, so it reads as one continuous strip of cards.
class ServiceGrid extends ConsumerWidget {
  const ServiceGrid({super.key, required this.onTap});

  final ValueChanged<ServiceItem> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(clientPreferencesProvider).language;
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
           child: _ServiceTile(item: kServiceItems[i], language: language, onTap: onTap),
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.item, required this.language, required this.onTap});

  final ServiceItem item;
  final String language;
  final ValueChanged<ServiceItem> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(item),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                 color: AppColors.clientSurface(context),
                 border: Border.all(color: AppColors.clientBorder(context)),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: AppIcon(item.icon, size: 26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
             clientLabel(item.label, item.swahili, language),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
             style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.clientText(context)),
          ),
        ],
      ),
    );
  }
}
