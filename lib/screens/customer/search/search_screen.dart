import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../state/auth_state.dart';
import '../../../state/catalog_state.dart';
import '../../../state/search_state.dart' show kFilterOptions, filteredShops, searchProvider;
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../home/widgets/shop_card.dart';
import '../../../widgets/round_back_button.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(shopsProvider.notifier).load();
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final search = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    final allShops = ref.watch(shopsProvider).items;
    final shops = filteredShops(allShops, search);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
              child: Row(
                children: [
                  const RoundBackButton(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.creamDark),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const AppIcon(AppIcons.search, size: 16),
                          const SizedBox(width: 9),
                          Expanded(
                            child: TextField(
                              onChanged: notifier.setQuery,
                              decoration: InputDecoration.collapsed(
                                hintText: "Try 'dry clean suit'",
                                hintStyle: AppText.sans(fontWeight: FontWeight.w600, color: AppColors.muted),
                              ),
                              style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                itemCount: kFilterOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final label = kFilterOptions[i];
                  final active = search.filter == label;
                  return _FilterChip(label: label, active: active, onTap: () => notifier.setFilter(label));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
              child: Text(
                '${shops.length} shops near you',
                style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
            ),
            Expanded(
              child: _loading
                  ? const _ExploreLoading()
                  : shops.isEmpty
                  ? Center(
                      child: Text(
                        'No shops match these filters',
                        style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                      itemCount: shops.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => ShopListTile(
                        shop: shops[i],
                        onTap: () {
                          if (gateGuest(
                            ref,
                            context,
                            'Log in as a customer to view ${shops[i].name}.',
                            redirectPath: '/detail',
                            redirectExtra: shops[i],
                          )) {
                            return;
                          }
                          context.push('/detail', extra: shops[i]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreLoading extends StatelessWidget {
  const _ExploreLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(strokeWidth: 3, color: AppColors.teal, backgroundColor: AppColors.tealMuted),
                const Icon(Icons.location_searching_rounded, size: 22, color: AppColors.amber),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Finding nearby vendors…', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.teal : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: active ? AppColors.teal : AppColors.creamDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          child: Text(
            label,
            style: AppText.sans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.cream : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
