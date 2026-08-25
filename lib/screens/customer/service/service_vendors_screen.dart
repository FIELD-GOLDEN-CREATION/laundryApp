import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/menu_item.dart';
import '../../../models/shop.dart';
import '../home/widgets/service_grid.dart';
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
  const ServiceVendorsScreen({super.key, required this.service});
  final String service;

  @override
  ConsumerState<ServiceVendorsScreen> createState() => _ServiceVendorsScreenState();
}

class _ServiceVendorsScreenState extends ConsumerState<ServiceVendorsScreen> {
  String get service => widget.service;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(shopsProvider.notifier).load());
  }

  int get _serviceIndex {
    for (var i = 0; i < kServiceItems.length; i++) {
      if (kServiceItems[i].label == service) return i;
    }
    return 0;
  }

  double priceFor(Shop shop) => (shop.priceFromTzs * (1 + (_serviceIndex % 4) * 0.18)).roundToDouble();

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final language = ref.watch(clientPreferencesProvider).language;
    final vendors = [...ref.watch(shopsProvider).items]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

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
                    Text(clientLabel('$service near you', '$service zilizo karibu nawe', language), style: AppText.serif(fontSize: 21, color: AppColors.clientText(context))),
                    const SizedBox(height: 2),
                    Text(clientLabel('Nearest vendors Â· tap to order', 'Wauzaji wa karibu Â· gusa kuagiza', language), style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context))),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                itemCount: vendors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 11),
                itemBuilder: (_, i) {
                  final vendor = vendors[i];
                  final price = priceFor(vendor);
                  return Material(
                    color: AppColors.clientSurface(context),
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        final key = 'svc:${vendor.name}:$service';
                        if ((ref.read(cartProvider)[key] ?? 0) == 0) {
                          // One order goes to one vendor â€” confirm before a
                          // second shop's item lands in someone else's basket.
                          if (!await ensureBasketShop(context, ref, vendor.name)) return;
                          ref.read(fulfillmentProvider.notifier).addServiceItem(MenuItem(key: key, name: service, unit: '${vendor.name} Â· per service', initial: service.isEmpty ? 'S' : service[0].toUpperCase(), price: price));
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
                            Text('${vendor.distanceKm} km Â· ${vendor.rating} â˜…', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context))),
                          ])),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(999)), child: Text('${formatMoney(price)} /pc', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.teal))),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
                        ]),
                      ),
                    ),
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
