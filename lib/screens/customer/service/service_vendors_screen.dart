import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/menu_item.dart';
import '../../../models/shop.dart';
import '../../../state/cart_state.dart';
import '../../../state/catalog_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../state/fulfillment_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/cart_math.dart';
import '../../../widgets/basket_shop_guard.dart';
import '../../../widgets/remote_image.dart';
import '../../../widgets/round_back_button.dart';

class ServiceVendorsScreen extends ConsumerStatefulWidget {
  const ServiceVendorsScreen({super.key, required this.categoryId, required this.categoryName});

  final String categoryId;
  final String categoryName;

  @override
  ConsumerState<ServiceVendorsScreen> createState() => _ServiceVendorsScreenState();
}

class _ServiceVendorsScreenState extends ConsumerState<ServiceVendorsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(shopsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(clientPreferencesProvider).language;
    final allShops = ref.watch(shopsProvider).items;
    final offersAsync = ref.watch(categoryShopsProvider(widget.categoryId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: Row(children: [
                RoundBackButton(onPressed: () => context.pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(clientLabel('${widget.categoryName} near you', '${widget.categoryName} zilizo karibu nawe', language), style: AppText.serif(fontSize: 21, color: AppColors.clientText(context))),
                    const SizedBox(height: 2),
                    Text(clientLabel('Nearest vendors · tap to order', 'Wauzaji wa karibu · gusa kuagiza', language), style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context))),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: offersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => Center(
                  child: Text(
                    clientLabel('Could not load vendors.', 'Imeshindikana kupata wauzaji.', language),
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                  ),
                ),
                data: (offers) {
                  final entries = <(Shop, CategoryShopOffer)>[];
                  for (final offer in offers) {
                    Shop? match;
                    for (final s in allShops) {
                      if (s.slotId == offer.shopId) {
                        match = s;
                        break;
                      }
                    }
                    if (match != null) entries.add((match, offer));
                  }
                  entries.sort((a, b) => a.$1.distanceKm.compareTo(b.$1.distanceKm));

                  if (entries.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          clientLabel('No vendors offer this yet.', 'Hakuna muuzaji anayetoa hii bado.', language),
                          textAlign: TextAlign.center,
                          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 11),
                    itemBuilder: (_, i) {
                      final (vendor, offer) = entries[i];
                      return Material(
                        color: AppColors.clientSurface(context),
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () async {
                            final key = offer.itemId;
                            if ((ref.read(cartProvider)[key] ?? 0) == 0) {
                              // One order goes to one vendor — confirm before
                              // a second shop's item lands in someone else's
                              // basket.
                              if (!await ensureBasketShop(context, ref, vendor.name, shopId: vendor.slotId, shopSlug: vendor.listSlotId)) return;
                              ref.read(fulfillmentProvider.notifier).addServiceItem(MenuItem(
                                    key: key,
                                    name: offer.itemName.isNotEmpty ? offer.itemName : widget.categoryName,
                                    unit: '${vendor.name} · from',
                                    initial: offer.itemName.isNotEmpty ? offer.itemName[0].toUpperCase() : 'S',
                                    price: offer.startingPriceTzs,
                                  ));
                              ref.read(cartProvider.notifier).setQty(key, 1);
                            }
                            if (context.mounted) context.push('/cart');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.clientBorder(context)), borderRadius: BorderRadius.circular(20)),
                            child: Row(children: [
                              SizedBox(width: 52, height: 52, child: RemoteImage(url: vendor.imageUrl, fallback: 'Shop', borderRadius: 14)),
                              const SizedBox(width: 13),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(vendor.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                                const SizedBox(height: 3),
                                Text('${vendor.distanceKm} km · ${vendor.rating} ★', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context))),
                              ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(999)),
                                child: Text('${formatMoney(offer.startingPriceTzs)} ${offer.itemUnit}', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.teal)),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
                            ]),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
