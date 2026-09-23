import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/app_icons.dart';
import '../../../models/service_package.dart';
import '../../../state/catalog_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/video_background.dart';
import 'widgets/package_showcase_card.dart';

/// Professional Packages page: every active package across vendors, with
/// name search + package-type filter. Cards match the home carousel design.
class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  String _query = '';
  PackageKind? _type;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(allPackagesProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(clientPreferencesProvider).language;
    final state = ref.watch(allPackagesProvider);
    // Dark + sky themes extend the body behind the floating nav bar.
    final immersive =
        AppColors.isClientDark(context) ||
        ref.watch(clientPreferencesProvider.select((s) => s.sky));
    final q = _query.trim().toLowerCase();
    final packages = state.items.where((p) {
      if (_type != null && p.kind != _type) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.tagline.toLowerCase().contains(q) ||
          p.shopName.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: ClientBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                toolbarHeight: 0,
                collapsedHeight: 62,
                expandedHeight: 190,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.teal,
                              Color(0xFF2A7D78),
                              Color(0xFF134E4A),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -30,
                              top: -40,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 14,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  clientLabel(
                                    'Packages',
                                    'Vifurushi',
                                    language,
                                  ),
                                  style: AppText.serif(
                                    fontSize: 26,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  packages.isEmpty
                                      ? clientLabel(
                                          'No packages found',
                                          'Hakuna vifurushi',
                                          language,
                                        )
                                      : clientLabel(
                                          '${packages.length} packages from top vendors',
                                          'Vifurushi ${packages.length} kutoka kwa wauzaji bora',
                                          language,
                                        ),
                                  style: AppText.sans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(54),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.clientSurface(context),
                        border: Border.all(
                          color: AppColors.clientBorder(context),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          AppIcon(
                            AppIcons.search,
                            size: 16,
                            color: AppColors.clientMutedIcon(context),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: TextField(
                              onChanged: (v) =>
                                  setState(() => _query = v),
                              decoration: InputDecoration.collapsed(
                                hintText: clientLabel(
                                  'Search packages or shops',
                                  'Tafuta vifurushi au maduka',
                                  language,
                                ),
                                hintStyle: AppText.sans(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.clientSecondaryText(
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
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        itemCount: PackageKind.values.length + 1,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return _TypeChip(
                              label: clientLabel('All', 'Zote', language),
                              active: _type == null,
                              onTap: () => setState(() => _type = null),
                            );
                          }
                          final kind = PackageKind.values[i - 1];
                          return _TypeChip(
                            label: _typeLabel(kind, language),
                            active: _type == kind,
                            onTap: () => setState(
                              () => _type = _type == kind ? null : kind,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              if (state.isLoading && state.items.isEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (packages.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 300,
                    child: Center(
                      child: Text(
                        clientLabel(
                          'Try another search or filter',
                          'Jaribu utafutaji mwingine',
                          language,
                        ),
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
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    immersive ? 116 : 24,
                  ),
                  sliver: SliverList.separated(
                    itemCount: packages.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 14),
                    itemBuilder: (_, i) => SizedBox(
                      height: 300,
                      child: PackageShowcaseCard(
                        pkg: packages[i],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(PackageKind kind, String language) {
    final en = switch (kind) {
      PackageKind.weight => 'Weight',
      PackageKind.itemCount => 'Items',
      PackageKind.household => 'Cleaning',
    };
    if (language != 'Swahili') return en;
    return switch (kind) {
      PackageKind.weight => 'Kilo',
      PackageKind.itemCount => 'Vitu',
      PackageKind.household => 'Usafi',
    };
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
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
