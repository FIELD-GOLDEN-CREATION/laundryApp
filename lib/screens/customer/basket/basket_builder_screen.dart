import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/laundry_category.dart';
import '../../../state/basket_builder_state.dart';
import '../../../state/catalog_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/currency.dart';
import '../../../widgets/remote_image.dart';
import '../../../widgets/skeleton_loader.dart';

/// Step 1 of the basket flow: type to find laundry items (with live
/// suggestions as you type), pick each item and set how many of each, then
/// continue to vendor search.
class BasketBuilderScreen extends ConsumerStatefulWidget {
  const BasketBuilderScreen({super.key});

  @override
  ConsumerState<BasketBuilderScreen> createState() => _BasketBuilderScreenState();
}

class _BasketBuilderScreenState extends ConsumerState<BasketBuilderScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _categoryId = 'all';

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
    final language = ref.watch(clientPreferencesProvider).language;
    final catalog = ref.watch(categoriesProvider);
    final draft = ref.watch(basketBuilderProvider);
    final builder = ref.read(basketBuilderProvider.notifier);

    final allItems = <LaundryItem>[
      for (final c in catalog.items)
        for (final i in c.items) i,
    ];

    final visible = allItems.where((i) {
      final inCategory = _categoryId == 'all' ||
          catalog.items.any((c) => c.id == _categoryId && c.items.any((x) => x.id == i.id));
      if (!inCategory) return false;
      if (_query.isEmpty) return true;
      final hay = '${i.name} ${i.nameSwahili} ${i.unit}'.toLowerCase();
      return hay.contains(_query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(clientLabel('Create basket', 'Tengeneza kikapu', language)),
        actions: [
          if (!draft.isEmpty)
            TextButton(
              onPressed: builder.clear,
              child: Text(clientLabel('Clear', 'Futa', language)),
            ),
        ],
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
                    clientLabel(
                      'Type an item, set how many, then find the best vendor.',
                      'Andika kipengee, weka idadi, kisha tafuta muuzaji bora.',
                      language,
                    ),
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  // ── Search: typing filters the catalogue live ──
                  TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: clientLabel('Search shirts, suits, duvets…', 'Tafuta shati, suti, mashuka…', language),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => _searchCtrl.clear(),
                            ),
                      filled: true,
                      fillColor: AppColors.cream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Category suggestions ──
                  SizedBox(
                    height: 36,
                    child: catalog.isLoading && catalog.items.isEmpty
                        ? Skeleton(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: 4,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (_, i) =>
                                  SkeletonBox(width: i == 0 ? 48 : 84, height: 36, borderRadius: 12),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: catalog.items.length + 1,
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final id = i == 0 ? 'all' : catalog.items[i - 1].id;
                              final label = i == 0
                                  ? clientLabel('All', 'Zote', language)
                                  : clientLabel(catalog.items[i - 1].name, catalog.items[i - 1].nameSwahili, language);
                              final active = _categoryId == id;
                              return ChoiceChip(
                                label: Text(label),
                                selected: active,
                                onSelected: (_) => setState(() => _categoryId = id),
                                selectedColor: AppColors.teal,
                                backgroundColor: AppColors.cream,
                                labelStyle: AppText.sans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: active ? Colors.white : AppColors.slate,
                                ),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: catalog.isLoading && allItems.isEmpty
                    ? const _BasketBuilderSkeleton(key: ValueKey('skeleton'))
                    : visible.isEmpty
                        ? Center(
                            key: const ValueKey('empty'),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                clientLabel(
                                  'No items match — try another word.',
                                  'Hakuna kipengee kinacholingana — jaribu neno jingine.',
                                  language,
                                ),
                                textAlign: TextAlign.center,
                                style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                              ),
                            ),
                          )
                        : ListView.separated(
                            key: const ValueKey('list'),
                            padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                            itemCount: visible.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final item = visible[i];
                              final qty = draft.quantities[item.id] ?? 0;
                              return _ItemRow(
                                item: item,
                                language: language,
                                qty: qty,
                                onRemove: () => builder.setQty(item.id, -1),
                                onAdd: () => builder.setQty(item.id, 1),
                              );
                            },
                          ),
              ),
            ),
            // ── Footer: continue to vendor search ──
            Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.creamDark)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            draft.isEmpty
                                ? clientLabel('Basket is empty', 'Kikapu kiko wazi', language)
                                : '${draft.totalQty} ${clientLabel('items', 'vitu', language)} · ${draft.distinctCount} ${clientLabel('kinds', 'aina', language)}',
                            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            clientLabel('Totals are priced per vendor next', 'Jumla itahesabiwa kwa kila muuzaji', language),
                            style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: draft.isEmpty
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              context.push('/vendor-results');
                            },
                      icon: const Icon(Icons.storefront_rounded, size: 18),
                      label: Text(clientLabel('Find vendor', 'Tafuta muuzaji', language)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.language,
    required this.qty,
    required this.onRemove,
    required this.onAdd,
  });

  final LaundryItem item;
  final String language;
  final int qty;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final selected = qty > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: selected ? AppColors.teal : AppColors.creamDark, width: selected ? 1.6 : 1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52,
              height: 52,
              child: RemoteImage(url: item.imageUrl, fallback: item.name, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language == 'Swahili' && item.nameSwahili.isNotEmpty ? item.nameSwahili : item.name,
                  style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  item.unit.isNotEmpty ? item.unit : clientLabel('per piece', 'kwa kipande', language),
                  style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
                if (item.priceTzs > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${clientLabel('from', 'kuanzia', language)} ${formatTzs(item.priceTzs)}',
                    style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.teal),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ── Qty stepper ──
          Container(
            decoration: BoxDecoration(
              color: selected ? AppColors.teal : AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: qty == 0 ? null : onRemove,
                  icon: const Icon(Icons.remove_rounded, size: 17),
                  color: selected ? Colors.white : AppColors.slate,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
                SizedBox(
                  width: 26,
                  child: Text(
                    '$qty',
                    textAlign: TextAlign.center,
                    style: AppText.sans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : AppColors.slate,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  color: selected ? Colors.white : AppColors.slate,
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

class _BasketBuilderSkeleton extends StatelessWidget {
  const _BasketBuilderSkeleton({super.key});

  static const _rowCount = 7;

  @override
  Widget build(BuildContext context) => Skeleton(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rowCount,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => const _BasketItemRowSkeleton(),
        ),
      );
}

class _BasketItemRowSkeleton extends StatelessWidget {
  const _BasketItemRowSkeleton();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.clientSurfaceRaised(context),
          border: Border.all(color: AppColors.clientBorder(context)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 52, height: 52, borderRadius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLine(width: 120),
                  SizedBox(height: 6),
                  SkeletonLine(width: 64, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SkeletonBox(width: 84, height: 30, borderRadius: 12),
          ],
        ),
      );
}
