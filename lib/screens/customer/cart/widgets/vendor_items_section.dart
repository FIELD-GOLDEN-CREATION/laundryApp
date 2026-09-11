import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/menu_item.dart';
import '../../../../state/catalog_state.dart';
import '../../../../state/client_preferences_state.dart';
import '../../../../state/vendor_basket.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/text_styles.dart';
import '../../../../utils/cart_math.dart';
import '../../../../widgets/remote_image.dart';

/// Inline "add more items" browser shown inside the cart screen. Groups the
/// vendor's own price list (from [shopDetailProvider]) under the shop's
/// global category names — resolved client-side by matching item ids
/// against [categoriesProvider], since the vendor price list itself carries
/// no category info — so a customer can add more of this vendor's items
/// without leaving the basket.
class VendorItemsSection extends ConsumerStatefulWidget {
  const VendorItemsSection({super.key, required this.shopId, required this.shopSlug, required this.language});

  final String shopId;
  final String shopSlug;
  final String language;

  @override
  ConsumerState<VendorItemsSection> createState() => _VendorItemsSectionState();
}

class _VendorItemsSectionState extends ConsumerState<VendorItemsSection> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final cats = ref.read(categoriesProvider).items;
      if (cats.isEmpty || cats.every((c) => c.items.isEmpty)) {
        ref.read(categoriesProvider.notifier).load(withItems: true);
      }
    });
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shopSlug.isEmpty) return const SizedBox.shrink();

    final language = widget.language;
    final categories = ref.watch(categoriesProvider).items;
    final priceListAsync = ref.watch(shopDetailProvider(widget.shopSlug));
    final qty = ref.watch(basketsProvider.select((m) => m[widget.shopId]?.qty)) ?? const <String, int>{};
    final basketsNotifier = ref.read(basketsProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: priceListAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            clientLabel("Couldn't load this vendor's items.", 'Imeshindwa kupakia vitu vya muuzaji.', language),
            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
          ),
        ),
        data: (priceList) {
          if (priceList.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                clientLabel('No items available from this vendor yet.', 'Hakuna vitu vya muuzaji huyu bado.', language),
                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
              ),
            );
          }

          final itemCategoryOf = <String, String>{};
          for (final c in categories) {
            for (final it in c.items) {
              itemCategoryOf[it.id] = c.id;
            }
          }

          bool matchesQuery(MenuItem item) => _query.isEmpty || item.name.toLowerCase().contains(_query);

          final grouped = <String, List<MenuItem>>{};
          for (final item in priceList) {
            if (!matchesQuery(item)) continue;
            final itemId = item.key.split(':').last;
            final catId = itemCategoryOf[itemId] ?? '_other';
            grouped.putIfAbsent(catId, () => []).add(item);
          }

          final sections = <(String, String, List<MenuItem>)>[
            for (final c in categories)
              if (grouped[c.id]?.isNotEmpty ?? false) (c.id, clientLabel(c.name, c.nameSwahili, language), grouped[c.id]!),
            if (grouped['_other']?.isNotEmpty ?? false)
              ('_other', clientLabel('Other items', 'Vitu vingine', language), grouped['_other']!),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clientLabel('Add more from this vendor', 'Ongeza zaidi kutoka kwa muuzaji', language),
                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clientText(context)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: clientLabel('Search this vendor\'s items…', 'Tafuta vitu vya muuzaji…', language),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        ),
                  filled: true,
                  fillColor: AppColors.clientSurfaceRaised(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
              ),
              const SizedBox(height: 14),
              if (sections.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    clientLabel('No items match — try another word.', 'Hakuna kipengee kinacholingana — jaribu neno jingine.', language),
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                  ),
                )
              else
                for (final section in sections) ...[
                  // A search overrides manual collapse so matches are always
                  // visible — otherwise a hit could land inside a category
                  // the customer never opened.
                  _CategoryHeader(
                    label: section.$2,
                    count: section.$3.length,
                    expanded: _query.isNotEmpty || _expandedCategories.contains(section.$1),
                    onTap: () => setState(() {
                      if (_expandedCategories.contains(section.$1)) {
                        _expandedCategories.remove(section.$1);
                      } else {
                        _expandedCategories.add(section.$1);
                      }
                    }),
                  ),
                  if (_query.isNotEmpty || _expandedCategories.contains(section.$1)) ...[
                    const SizedBox(height: 8),
                    for (final item in section.$3) ...[
                      _VendorItemRow(
                        item: item,
                        language: language,
                        qty: qty[item.key] ?? 0,
                        onRemove: () => basketsNotifier.setQty(widget.shopId, item.key, -1),
                        onAdd: () => basketsNotifier.setQty(widget.shopId, item.key, 1),
                      ),
                      if (item != section.$3.last) const SizedBox(height: 8),
                    ],
                  ],
                  if (section != sections.last) const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.label, required this.count, required this.expanded, required this.onTap});

  final String label;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.clientSurfaceRaised(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: expanded ? AppColors.teal.withValues(alpha: 0.4) : AppColors.clientBorder(context)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 20,
                color: AppColors.clientSecondaryText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorItemRow extends StatelessWidget {
  const _VendorItemRow({
    required this.item,
    required this.language,
    required this.qty,
    required this.onRemove,
    required this.onAdd,
  });

  final MenuItem item;
  final String language;
  final int qty;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final selected = qty > 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.clientSurfaceRaised(context),
        border: Border.all(color: selected ? AppColors.teal : AppColors.clientBorder(context), width: selected ? 1.6 : 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 44,
              height: 44,
              child: RemoteImage(url: item.imageUrl, fallback: item.name, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                const SizedBox(height: 2),
                Text(formatMoney(item.price), style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.teal)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: selected ? AppColors.teal : AppColors.clientBorder(context).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: qty == 0 ? null : onRemove,
                  icon: const Icon(Icons.remove_rounded, size: 16),
                  color: selected ? Colors.white : AppColors.clientSecondaryText(context),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
                SizedBox(
                  width: 22,
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: AppText.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.clientSecondaryText(context),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  color: selected ? Colors.white : AppColors.clientSecondaryText(context),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
