import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/menu_item.dart';
import '../../../models/service_package.dart';
import '../../../models/shop.dart';
import '../../../state/cart_addons_state.dart';
import '../../../state/cart_state.dart';
import '../../../state/cart_promo_state.dart';
import '../../../state/catalog_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../state/fulfillment_state.dart';
import '../../../state/vendor_catalog_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/cart_math.dart';
import '../../../widgets/curved_clipper.dart';
import '../../../widgets/round_back_button.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final fulfillment = ref.watch(fulfillmentProvider);
    final language = ref.watch(clientPreferencesProvider).language;
    final priced = fulfillment.pricedItems;
    final pkg = ref.watch(cartPackageProvider);
    final pkgNotifier = ref.read(cartPackageProvider.notifier);
    final lines = priced.where((i) => (qty[i.key] ?? 0) > 0).toList();
    final subtotal = cartSubtotal(qty, [], priced);
    final delivery = fulfillment.isDelivery ? fulfillment.deliveryFeeTzs : 0;
    final promoState = ref.watch(cartPromoProvider);
    final discount = promoState.discountAmount;
    // Add-ons from vendor catalog
    final vendorAddons = ref.watch(vendorCatalogProvider.select((s) => s.addons));
    final cartAddons = ref.watch(cartAddonsProvider);
    final cartAddonsNotifier = ref.read(cartAddonsProvider.notifier);
    final addonTotal = cartAddonsNotifier.totalFor(vendorAddons);
    final total = (subtotal - discount).clamp(0.0, double.infinity) + delivery + addonTotal;

    // Back to the shop the basket already belongs to â€” resolved from the
    // live shop list by name.
    void openBasketShop() {
      final shops = ref.read(shopsProvider).items;
      Shop? match;
      for (final s in shops) {
        if (s.name == fulfillment.shop) {
          match = s;
          break;
        }
      }
      if (match != null) context.push('/detail', extra: match);
    }

    return Scaffold(
      backgroundColor: AppColors.isClientDark(context) ? const Color(0xFF0A1117) : AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: Row(children: [
                RoundBackButton(onPressed: () => context.pop()),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(clientLabel('Your basket', 'Kikapu chako', language), style: AppText.serif(fontSize: 24, color: AppColors.clientText(context))),
                    Text(fulfillment.shop, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context))),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(99)),
                  child: Row(children: [
                    const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.amber),
                    const SizedBox(width: 5),
                    Text('${cartItemCount(qty, [], priced)}', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.amber)),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: lines.isEmpty
                  ? _EmptyBasket(onBrowse: openBasketShop, language: language)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
                      children: [
                        _ShopBanner(shop: fulfillment.shop, isDelivery: fulfillment.isDelivery, language: language),
                        const SizedBox(height: 18),
                        if (pkg != null) ...[
                          _PackageBundleCard(pkg: pkg, onRemove: () => pkgNotifier.removePackage(notifier), language: language),
                          const SizedBox(height: 18),
                        ],
                        Text(clientLabel('How do you want your order?', 'Unataka oda yako ipokeleweje?', language), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))),
                        const SizedBox(height: 9),
                        Row(children: [
                          Expanded(child: _FulfillmentTile(
                            icon: Icons.local_shipping_outlined,
                            title: clientLabel('Driver delivery', 'Usafirishaji', language),
                            sub: clientLabel('We pick up & deliver to your door', 'Tunachukua na kupeleka mlangoni', language),
                            time: clientLabel('Pickup window', 'Muda wa kuchukua', language),
                            selected: fulfillment.isDelivery,
                            onTap: () => ref.read(fulfillmentProvider.notifier).setMode('delivery'),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _FulfillmentTile(
                            icon: Icons.storefront_outlined,
                            title: clientLabel('Self drop-off', 'Unapeleka mwenyewe', language),
                            sub: clientLabel('Promise order â€” you take it to the shop', 'Oda ya ahadi â€” unapeleka dukani', language),
                            time: clientLabel('Free, no delivery fee', 'Bure, hakuna nauli', language),
                            selected: !fulfillment.isDelivery,
                            onTap: () => ref.read(fulfillmentProvider.notifier).setMode('self'),
                          )),
                        ]),
                        const SizedBox(height: 20),
                        Row(children: [
                          Text(pkg != null ? clientLabel('Additional items', 'Vitu nyongeza', language) : clientLabel('Your items', 'Vitu vyako', language), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))),
                          const Spacer(),
                          Text('${cartItemCount(qty, [], priced)} ${clientLabel('items', 'vitu', language)}', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                        ]),
                        const SizedBox(height: 10),
                        for (final item in lines) ...[
                          _CartRow(item: item, qty: qty[item.key] ?? 0, notifier: notifier, language: language),
                          if (item != lines.last) const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 13),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: openBasketShop,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.teal.withValues(alpha: 0.55), width: 1.5),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Text(
                                  clientLabel('+ Add more items', '+ Ongeza vitu', language),
                                  style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _AddOnsSection(
                          addons: vendorAddons,
                          selectedIndices: cartAddons,
                          onToggle: (i) => cartAddonsNotifier.toggle(i),
                          language: language,
                        ),
                        const SizedBox(height: 18),
                        _PromoCodeSection(subtotal: subtotal, language: language),
                        const SizedBox(height: 18),
                        _SummaryPanel(
                          subtotal: subtotal,
                          delivery: delivery,
                          isDelivery: fulfillment.isDelivery,
                          discount: discount,
                          promoState: promoState,
                          addonTotal: addonTotal,
                          total: total,
                          language: language,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: ClipPath(
          clipper: const CurvedTopClipper(depth: 24, lift: -16),
          child: Material(
            color: AppColors.amber,
            elevation: 14,
            shadowColor: AppColors.amber.withValues(alpha: 0.35),
            child: InkWell(
              onTap: () => lines.isEmpty ? openBasketShop() : context.push('/schedule'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 16),
                child: Row(children: [
                  Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      lines.isEmpty ? clientLabel('Browse services', 'Vinjari huduma', language) : clientLabel('Proceed to schedule', 'Endelea kwenye ratiba', language),
                      style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.cream),
                    ),
                    const SizedBox(height: 2),
                    Text(formatMoney(total), style: AppText.serif(fontSize: 19, color: AppColors.cream)),
                  ]),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded, size: 24, color: AppColors.cream),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PackageBundleCard extends StatelessWidget {
  const _PackageBundleCard({required this.pkg, required this.onRemove, required this.language});
  final ServicePackage pkg;
  final VoidCallback onRemove;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.tealMuted, AppColors.tealMuted.withValues(alpha: 0.3)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(8)),
                child: Text('PACKAGE', style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.cream, letterSpacing: 0.8)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(pkg.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal)),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded, size: 20, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(pkg.tagline, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                for (final pi in pkg.packageItems) ...[
                  Row(
                    children: [
                      Text('${pi.qty}Ã—', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.teal)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(pi.itemName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate))),
                      Text(formatMoney(pi.lineTotal), style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slate)),
                    ],
                  ),
                  if (pi != pkg.packageItems.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(clientLabel('Package total', 'Jumla ya kifurushi', language), style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.teal)),
              Text(formatMoney(pkg.priceTzs), style: AppText.serif(fontSize: 17, color: AppColors.teal)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShopBanner extends StatelessWidget {
  const _ShopBanner({required this.shop, required this.isDelivery, required this.language});

  final String shop;
  final bool isDelivery;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.teal, Color(0xFF124944)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(15)),
          alignment: Alignment.center,
          child: Icon(isDelivery ? Icons.local_shipping_outlined : Icons.storefront_outlined, color: AppColors.cream, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(shop, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cream)),
          const SizedBox(height: 3),
          Text(
            isDelivery ? clientLabel('Pickup + delivery to your door', 'Kuchukua na kupeleka mlangoni', language) : clientLabel('Drop off your laundry at the shop', 'Peleka nguo zako dukani', language),
            style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.75)),
          ),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppColors.mint.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(99)),
          child: Text(isDelivery ? clientLabel('Next-day', 'Siku inayofuata', language) : clientLabel('Promise', 'Ahadi', language), style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.mint, letterSpacing: 0.4)),
        ),
      ]),
    );
  }
}

class _FulfillmentTile extends StatelessWidget {
  const _FulfillmentTile({required this.icon, required this.title, required this.sub, required this.time, required this.selected, required this.onTap});

  final IconData icon;
  final String title;
  final String sub;
  final String time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isClientDark(context);
    return Material(
      color: selected ? (dark ? const Color(0xFF193B3B) : AppColors.tealMuted) : AppColors.clientSurface(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(border: Border.all(color: selected ? AppColors.teal : AppColors.clientBorder(context), width: 1.6), borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: selected ? AppColors.teal : AppColors.clientSecondaryText(context), size: 21),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 21,
                height: 21,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.teal : Colors.transparent,
                  border: Border.all(color: selected ? AppColors.teal : AppColors.clientBorder(context), width: 1.8),
                ),
                alignment: Alignment.center,
                child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
              ),
            ]),
            const SizedBox(height: 10),
            Text(title, style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
            const SizedBox(height: 3),
            Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.35, color: AppColors.clientSecondaryText(context))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: selected ? AppColors.teal.withValues(alpha: dark ? 0.3 : 0.14) : AppColors.clientBorder(context).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.schedule_rounded, size: 11, color: selected ? AppColors.teal : AppColors.clientSecondaryText(context)),
                const SizedBox(width: 4),
                Text(time, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w700, color: selected ? AppColors.teal : AppColors.clientSecondaryText(context))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.item, required this.qty, required this.notifier, required this.language});

  final MenuItem item;
  final int qty;
  final CartNotifier notifier;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.teal, Color(0xFF124944)]),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(item.initial, style: AppText.serif(fontSize: 17, color: AppColors.cream)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                const SizedBox(height: 2),
                Text(item.unit, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatMoney(item.price * qty), style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.teal)),
              const SizedBox(height: 4),
              Row(
                children: [
                  _StepButton(symbol: 'âˆ’', bg: AppColors.clientSurfaceRaised(context), fg: AppColors.teal, onTap: () => notifier.setQty(item.key, -1)),
                  SizedBox(
                    width: 26,
                    child: Text('$qty', textAlign: TextAlign.center, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                  ),
                  _StepButton(symbol: '+', bg: AppColors.teal, fg: Colors.white, onTap: () => notifier.setQty(item.key, 1)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: clientLabel('Remove', 'Ondoa', language),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => notifier.setQty(item.key, -qty),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.clientSecondaryText(context)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.symbol, required this.bg, required this.fg, required this.onTap});

  final String symbol;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 24, height: 24, child: Center(child: Text(symbol, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w800, height: 1)))),
      ),
    );
  }
}

class _PromoCodeSection extends ConsumerStatefulWidget {
  const _PromoCodeSection({required this.subtotal, required this.language});
  final double subtotal;
  final String language;

  @override
  ConsumerState<_PromoCodeSection> createState() => _PromoCodeSectionState();
}

class _PromoCodeSectionState extends ConsumerState<_PromoCodeSection> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promoState = ref.watch(cartPromoProvider);
    final notifier = ref.read(cartPromoProvider.notifier);
    final hasPromo = promoState.hasPromo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 18,
                color: hasPromo ? AppColors.teal : AppColors.clientSecondaryText(context),
              ),
              const SizedBox(width: 8),
              Text(
                clientLabel('Promo code', 'Msimbo wa punguzo', widget.language),
                style: AppText.sans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.clientText(context),
                ),
              ),
              if (hasPromo) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    notifier.removePromo();
                    _controller.clear();
                  },
                  child: Text(
                    clientLabel('Remove', 'Ondoa', widget.language),
                    style: AppText.sans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (hasPromo) ...[
            // Applied promo display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.tealMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      promoState.appliedPromo?.code ?? '',
                      style: AppText.sans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cream,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promoState.appliedPromo?.title ?? '',
                          style: AppText.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                          ),
                        ),
                        Text(
                          _discountLabel(promoState, widget.language),
                          style: AppText.sans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded, size: 20, color: AppColors.teal),
                ],
              ),
            ),
          ] else ...[
            // Promo code input
            Container(
              decoration: BoxDecoration(
                color: AppColors.clientSurfaceRaised(context),
                border: Border.all(
                  color: promoState.promoError.isNotEmpty
                      ? AppColors.danger
                      : AppColors.clientBorder(context),
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: AppText.sans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.clientText(context),
                      ),
                      decoration: InputDecoration(
                        hintText: clientLabel('Enter promo code', 'Weka msimbo wa punguzo', widget.language),
                        hintStyle: AppText.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      onChanged: (v) => notifier.setPromo(v),
                      onSubmitted: (_) => notifier.applyPromo(widget.subtotal, ''),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    child: Material(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(10),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          _focusNode.unfocus();
                          notifier.applyPromo(widget.subtotal, '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Text(
                            clientLabel('Apply', 'Tumia', widget.language),
                            style: AppText.sans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cream,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (promoState.promoError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 14, color: AppColors.danger),
                  const SizedBox(width: 6),
                  Text(
                    promoState.promoError,
                    style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.danger),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _discountLabel(CartPromoState state, String lang) {
    if (state.appliedPromo == null) return '';
    final promo = state.appliedPromo!;
    if (promo.isPercentage) {
      return clientLabel(
        '${promo.discountValue.round()}% off Â· Save ${formatMoney(state.discountAmount)}',
        'Punguzo la ${promo.discountValue.round()}% Â· Okoa ${formatMoney(state.discountAmount)}',
        lang,
      );
    }
    return clientLabel(
      'Save ${formatMoney(state.discountAmount)}',
      'Okoa ${formatMoney(state.discountAmount)}',
      lang,
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.subtotal, required this.delivery, required this.isDelivery, required this.discount, required this.promoState, required this.addonTotal, required this.total, required this.language});

  final double subtotal;
  final int delivery;
  final bool isDelivery;
  final double discount;
  final CartPromoState promoState;
  final double addonTotal;
  final double total;
  final String language;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isClientDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 17),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF182631) : const Color(0xFFEDF5F4),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        Text(clientLabel('ORDER SUMMARY', 'MUHTASARI WA ODA', language), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))),
        const SizedBox(height: 12),
        _SummaryLine(label: clientLabel('Subtotal', 'Jumla ndogo', language), value: formatMoney(subtotal), context: context),
        if (discount > 0) ...[
          const SizedBox(height: 9),
          _SummaryLine(
            label: clientLabel('Discount', 'Punguzo', language),
            value: '-${formatMoney(discount)}',
            valueColor: AppColors.teal,
            context: context,
          ),
        ],
        const SizedBox(height: 9),
        if (isDelivery)
          _SummaryLine(label: clientLabel('Delivery', 'Usafirishaji', language), value: delivery > 0 ? formatMoney(delivery.toDouble()) : clientLabel('Quoted at schedule', 'Itakadiriwa kwenye ratiba', language), valueColor: AppColors.teal, context: context)
        else
          _SummaryLine(label: clientLabel('Self drop-off', 'Unapeleka mwenyewe', language), value: clientLabel('Free', 'Bure', language), valueColor: AppColors.teal, context: context),
        if (addonTotal > 0) ...[
          const SizedBox(height: 9),
          _SummaryLine(
            label: clientLabel('Add-on services', 'Huduma za nyongeza', language),
            value: formatMoney(addonTotal),
            valueColor: AppColors.teal,
            context: context,
          ),
        ],
        const SizedBox(height: 11),
        Divider(height: 1, color: AppColors.clientBorder(context)),
        const SizedBox(height: 11),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(clientLabel('Total', 'Jumla', language), style: AppText.sans(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (discount > 0)
                  Text(
                    formatMoney(subtotal + delivery),
                    style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted).copyWith(decoration: TextDecoration.lineThrough),
                  ),
                Text(formatMoney(total), style: AppText.serif(fontSize: 18, color: AppColors.teal)),
              ],
            ),
          ],
        ),
      ]),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value, this.valueColor = AppColors.slate, required this.context});

  final String label;
  final String value;
  final Color valueColor;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(this.context))),
        Text(value, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: valueColor)),
      ],
    );
  }
}

class _AddOnsSection extends StatelessWidget {
  const _AddOnsSection({required this.addons, required this.selectedIndices, required this.onToggle, required this.language});
  final List<VendorAddon> addons;
  final Set<int> selectedIndices;
  final void Function(int index) onToggle;
  final String language;

  @override
  Widget build(BuildContext context) {
    if (addons.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.clientSecondaryText(context)),
              const SizedBox(width: 8),
              Text(
                clientLabel('Add-on services', 'Huduma za nyongeza', language),
                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clientText(context)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            clientLabel('Extra services for your order', 'Huduma za ziada kwa oda yako', language),
            style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < addons.length; i++) ...[
            _AddonToggleRow(
              title: addons[i].title,
              price: addons[i].priceTzs,
              selected: selectedIndices.contains(i),
              onTap: () => onToggle(i),
              language: language,
            ),
            if (i < addons.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _AddonToggleRow extends StatelessWidget {
  const _AddonToggleRow({required this.title, required this.price, required this.selected, required this.onTap, required this.language});
  final String title;
  final double price;
  final bool selected;
  final VoidCallback onTap;
  final String language;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isClientDark(context);
    return Material(
      color: selected ? (dark ? const Color(0xFF193B3B) : AppColors.tealMuted) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? AppColors.teal : AppColors.clientBorder(context), width: 1.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.teal : Colors.transparent,
                  border: Border.all(color: selected ? AppColors.teal : AppColors.clientBorder(context), width: 1.8),
                ),
                alignment: Alignment.center,
                child: selected ? const Icon(Icons.check_rounded, size: 13, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clientText(context)),
                ),
              ),
              Text(
                formatMoney(price),
                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: selected ? AppColors.teal : AppColors.clientSecondaryText(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBasket extends StatelessWidget {
  const _EmptyBasket({required this.onBrowse, required this.language});

  final VoidCallback onBrowse;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(color: AppColors.tealMuted, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.local_laundry_service_outlined, size: 40, color: AppColors.teal),
          ),
          const SizedBox(height: 20),
          Text(clientLabel('Your basket is empty', 'Kikapu chako hakina kitu', language), style: AppText.serif(fontSize: 21, color: AppColors.clientText(context)), textAlign: TextAlign.center),
          const SizedBox(height: 7),
          Text(
            clientLabel('Choose a service like Ironing or Wash & Fold and a nearby vendor will take care of it.', 'Chagua huduma kama Kupiga pasi au Osha na kunja, na muuzaji wa karibu atakushughulikia.', language),
            textAlign: TextAlign.center,
            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, height: 1.4, color: AppColors.clientSecondaryText(context)),
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(18),
            elevation: 6,
            shadowColor: AppColors.teal.withValues(alpha: 0.3),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onBrowse,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                child: Text(clientLabel('Browse services', 'Vinjari huduma', language), style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.cream)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
