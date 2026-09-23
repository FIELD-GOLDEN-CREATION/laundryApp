import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../state/auth_state.dart';
import '../../../state/browse_location_state.dart';
import '../../../state/catalog_state.dart';
import '../../../state/search_state.dart'
    show kFilterOptions, filteredShops, searchProvider;
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/browse_location_sheet.dart';
import '../../../widgets/video_background.dart';
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
      if (mounted && !ref.read(browseLocationProvider).hasPrompted) {
        showBrowseLocationSheet(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final search = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    final allShops = ref.watch(shopsWithDistanceProvider);
    final shops = filteredShops(allShops, search);
    final browseLocation = ref.watch(browseLocationProvider);

    return Scaffold(
      body: ClientBackground(
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                snap: true,
                toolbarHeight: 0,
                collapsedHeight: 62,
                expandedHeight: 168,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      12 + MediaQuery.paddingOf(context).top,
                      22,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                          child: LocationPill(
                            label: browseLocation.hasLocation
                                ? browseLocation.label
                                : 'Set your location',
                            onTap: () =>
                                showBrowseLocationSheet(context, ref),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                            ),
                            itemCount: kFilterOptions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final label = kFilterOptions[i];
                              final active = search.filter == label;
                              return _FilterChip(
                                label: label,
                                active: active,
                                onTap: () => notifier.setFilter(label),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                          child: Text(
                            '${shops.length} shops near you',
                            style: AppText.sans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.clientSecondaryText(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(54),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                    child: Row(
                      children: [
                        const RoundBackButton(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.clientSurface(context),
                              border: Border.all(
                                color: AppColors.clientBorder(context),
                              ),
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
                                      hintStyle: AppText.sans(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            AppColors.clientSecondaryText(
                                          context,
                                        ),
                                      ),
                                    ),
                                    style: AppText.sans(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.clientText(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (shops.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: Center(
                      child: Text(
                        'No shops match these filters',
                        style: AppText.sans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.clientSecondaryText(context),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 112),
                  sliver: SliverList.separated(
                    itemCount: shops.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 12),
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
      ),
    );
  }
}


class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.teal : AppColors.clientSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: active ? AppColors.teal : AppColors.clientBorder(context),
        ),
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
              color: active
                  ? AppColors.cream
                  : AppColors.clientSecondaryText(context),
            ),
          ),
        ),
      ),
    );
  }
}
