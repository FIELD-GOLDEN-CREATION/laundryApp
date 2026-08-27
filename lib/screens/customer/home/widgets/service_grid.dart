import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../state/catalog_state.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../state/client_preferences_state.dart';

class ServiceItem {
  const ServiceItem(this.icon, this.label, this.swahili);
  final String icon;
  final String label;
  final String swahili;
}

// Retained only for `service_vendors_screen.dart`, which still matches
// against this fixed list until it's rewired to real per-category pricing.
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

// Best-effort icon for a real backend category name — categories are
// broader groupings than the old per-service mock list, so this maps by
// keyword rather than exact name.
String _iconForCategory(String name) {
  final n = name.toLowerCase();
  if (n.contains('foot') || n.contains('shoe') || n.contains('bag')) {
    return AppIcons.serviceShoeCare;
  }
  if (n.contains('formal') || n.contains('wool') || n.contains('outerwear') || n.contains('suit')) {
    return AppIcons.serviceSuits;
  }
  if (n.contains('bedding') || n.contains('household') || n.contains('heavy')) {
    return AppIcons.serviceBedding;
  }
  if (n.contains('bulk') || n.contains('add-on') || n.contains('addon')) {
    return AppIcons.serviceIroning;
  }
  return AppIcons.serviceWashFold;
}

/// The service icon row on Home, driven by real backend categories
/// (`categoriesProvider`) — every entry is reachable by swiping
/// horizontally, with no "see all" toggle and no visible scrollbar
/// affordance, so it reads as one continuous strip of cards.
class ServiceGrid extends ConsumerStatefulWidget {
  const ServiceGrid({super.key, required this.onTap});

  final ValueChanged<ServiceItem> onTap;

  @override
  ConsumerState<ServiceGrid> createState() => _ServiceGridState();
}

class _ServiceGridState extends ConsumerState<ServiceGrid> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(categoriesProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(clientPreferencesProvider).language;
    final categories = ref.watch(categoriesProvider).items;

    if (categories.isEmpty) {
      return const SizedBox(
        height: _kGridHeight,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final items = categories
        .map((c) => ServiceItem(_iconForCategory(c.name), c.name, c.nameSwahili))
        .toList();

    return SizedBox(
      height: _kGridHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => SizedBox(
            width: _kTileWidth,
            child: _ServiceTile(item: items[i], language: language, onTap: widget.onTap),
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
