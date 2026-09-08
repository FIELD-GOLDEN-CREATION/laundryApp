import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/menu_item.dart';
import '../../../state/auth_state.dart';
import '../../../state/basket_builder_state.dart';
import '../../../state/catalog_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../state/vendor_basket.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/currency.dart';

/// Step 2 of the basket flow: every nearby vendor priced for the exact
/// basket — total, distance in km, coverage — with the nearest and cheapest
/// given priority. Selecting a vendor fills their basket and continues to
/// the basket page.
class VendorResultsScreen extends ConsumerStatefulWidget {
  const VendorResultsScreen({super.key});

  @override
  ConsumerState<VendorResultsScreen> createState() => _VendorResultsScreenState();
}

class _VendorResultsScreenState extends ConsumerState<VendorResultsScreen> {
  QuoteSort _sort = QuoteSort.recommended;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(vendorQuotesProvider.notifier).search());
  }

  void _select(VendorQuote quote, String language) {
    final draft = ref.read(basketBuilderProvider);
    if (gateGuest(
      ref,
      context,
      'Log in as a customer to order from ${quote.shop.name}.',
      redirectPath: '/cart',
      redirectExtra: quote.shop.slotId,
    )) {
      return;
    }
    final baskets = ref.read(basketsProvider.notifier);
    baskets.clearBasket(quote.shop.slotId);
    baskets.setShopCatalog(
      quote.shop.slotId,
      shopName: quote.shop.name,
      shopSlug: quote.shop.listSlotId,
      items: quote.catalog,
    );
    for (final entry in draft.quantities.entries) {
      if (quote.prices.containsKey(entry.key)) {
        baskets.setQty(
          quote.shop.slotId,
          MenuItem.cartKey(quote.shop.listSlotId, entry.key),
          entry.value,
        );
      }
    }
    context.push('/cart', extra: quote.shop.slotId);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(clientPreferencesProvider).language;
    final draft = ref.watch(basketBuilderProvider);
    final quotesAsync = ref.watch(vendorQuotesProvider);
    final categories = ref.watch(categoriesProvider).items;
    final itemById = {for (final c in categories) for (final i in c.items) i.id: i};

    return Scaffold(
      appBar: AppBar(
        title: Text(clientLabel('Choose vendor', 'Chagua muuzaji', language)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.isEmpty
                        ? clientLabel('Your basket is empty.', 'Kikapu chako kiko wazi.', language)
                        : clientLabel(
                            '${draft.totalQty} items priced at each vendor near you.',
                            'Vitu ${draft.totalQty} vimehesabiwa kwa kila muuzaji karibu nawe.',
                            language,
                          ),
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  // ── Sort: nearest & cheapest get priority ──
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        for (final s in QuoteSort.values)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _sort = s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: s == _sort ? AppColors.teal : Colors.transparent,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Text(
                                  s == QuoteSort.recommended
                                      ? clientLabel('Best match', 'Bora', language)
                                      : s == QuoteSort.cheapest
                                          ? clientLabel('Cheapest', 'Rahisi', language)
                                          : clientLabel('Nearest', 'Karibu', language),
                                  textAlign: TextAlign.center,
                                  style: AppText.sans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: s == _sort ? Colors.white : AppColors.muted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: quotesAsync.when(
                loading: () => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, _) => Container(
                    height: 148,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clientLabel(
                            'Could not price vendors. Check connection and retry.',
                            'Imeshindikana kuhesabu. Angalia mtandao ujaribu tena.',
                            language,
                          ),
                          textAlign: TextAlign.center,
                          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => ref.read(vendorQuotesProvider.notifier).search(),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                          child: Text(clientLabel('Retry', 'Jaribu tena', language)),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (quotes) {
                  final sorted = sortQuotes(quotes, _sort);
                  if (sorted.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          clientLabel(
                            'No nearby vendor carries these items yet — try fewer items.',
                            'Hakuna muuzaji karibu mwenye vitu hivi — jaribu vitu vichache.',
                            language,
                          ),
                          textAlign: TextAlign.center,
                          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _QuoteCard(
                      quote: sorted[i],
                      rank: i + 1,
                      language: language,
                      itemById: itemById,
                      quantities: draft.quantities,
                      onSelect: () => _select(sorted[i], language),
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

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.rank,
    required this.language,
    required this.itemById,
    required this.quantities,
    required this.onSelect,
  });

  final VendorQuote quote;
  final int rank;
  final String language;
  final Map<String, dynamic> itemById;
  final Map<String, int> quantities;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final shop = quote.shop;
    final distance = quote.distanceKm < 0
        ? clientLabel('Distance unknown', 'Umbali haujulikani', language)
        : '${quote.distanceKm.toStringAsFixed(1)} ${clientLabel('km away', 'km', language)}';
    final highlight = quote.isRecommended || rank == 1 && quote.fullCoverage;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: highlight ? AppColors.teal : AppColors.creamDark,
          width: highlight ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tealMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  shop.name.isNotEmpty ? shop.name[0].toUpperCase() : '?',
                  style: AppText.sans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.teal),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(shop.name, style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.amber),
                        const SizedBox(width: 2),
                        Text(
                          shop.rating.isNotEmpty ? shop.rating : '—',
                          style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.teal),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            distance,
                            style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (quote.isRecommended)
                _Badge(label: clientLabel('#1 Best match', '#1 Bora', language), color: AppColors.teal, bg: AppColors.tealMuted),
              if (quote.isCheapest)
                _Badge(label: clientLabel('Cheapest', 'Rahisi zaidi', language), color: AppColors.amber, bg: AppColors.amberLight),
              if (quote.isNearest)
                _Badge(label: clientLabel('Nearest', 'Karibu zaidi', language), color: AppColors.teal, bg: AppColors.tealMuted),
              if (!quote.fullCoverage)
                _Badge(
                  label: '${quote.matched}/${quote.total} ${clientLabel('items', 'vitu', language)}',
                  color: AppColors.amber,
                  bg: AppColors.amberLight,
                ),
            ],
          ),
          if (!quote.fullCoverage && quote.missingNames.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              '${clientLabel('Missing', 'Hakuna', language)}: ${quote.missingNames.take(3).join(', ')}${quote.missingNames.length > 3 ? '…' : ''}',
              style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.amber),
            ),
          ],
          const SizedBox(height: 8),
          // ── Per-item price breakdown ──
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                clientLabel('Price breakdown', 'Muhtasari wa bei', language),
                style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal),
              ),
              children: [
                for (final entry in quantities.entries)
                  if (quote.prices.containsKey(entry.key))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_itemName(entry.key)} × ${entry.value}',
                              style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                            ),
                          ),
                          Text(
                            formatTzs(quote.prices[entry.key]! * entry.value),
                            style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clientLabel('TOTAL', 'JUMLA', language), style: AppText.eyebrow()),
                    const SizedBox(height: 2),
                    Text(formatTzs(quote.totalTzs), style: AppText.serif(fontSize: 21)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onSelect,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
                child: Text(clientLabel('Select', 'Chagua', language)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _itemName(String id) {
    final item = itemById[id];
    if (item == null) return 'Item';
    final name = (item.name as String?) ?? '';
    final sw = (item.nameSwahili as String?) ?? '';
    if (language == 'Swahili' && sw.isNotEmpty) return sw;
    return name.isNotEmpty ? name : 'Item';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
