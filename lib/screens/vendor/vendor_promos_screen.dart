import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/laundry_category.dart';
import '../../models/promo_offer.dart';
import '../../models/service_package.dart';
import '../../state/catalog_state.dart';
import '../../state/vendor_packages_state.dart';
import '../../state/vendor_promos_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/cart_math.dart';

class VendorPromosScreen extends ConsumerStatefulWidget {
  const VendorPromosScreen({super.key});

  @override
  ConsumerState<VendorPromosScreen> createState() => _VendorPromosScreenState();
}

class _VendorPromosScreenState extends ConsumerState<VendorPromosScreen> {
  @override
  void initState() {
    super.initState();
    // The promo list otherwise only ever reflects promos created in the
    // current app session — nothing fetched it from the backend before.
    Future.microtask(() => ref.read(vendorPromosProvider.notifier).loadPromos());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorPromosProvider);
    final notifier = ref.read(vendorPromosProvider.notifier);
    final activePromos = state.promos.where((p) => p.isActive && !p.isExpired).toList();
    final expiredPromos = state.promos.where((p) => p.isExpired || !p.isActive).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Discounts & Promotions', style: AppText.serif(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Create deals to attract customers and boost sales.',
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            _CreatePromoButton(
              onTap: () => _showPromoFormSheet(context, ref),
            ),
            const SizedBox(height: 24),
            if (activePromos.isNotEmpty) ...[
              Text('ACTIVE PROMOS', style: AppText.eyebrow()),
              const SizedBox(height: 12),
              for (final promo in activePromos) ...[
                _PromoCard(
                  promo: promo,
                  onToggle: () => notifier.togglePromoActive(promo.id),
                  onDelete: () => notifier.deletePromo(promo.id),
                ),
                const SizedBox(height: 10),
              ],
            ],
            if (expiredPromos.isNotEmpty) ...[
              Text('EXPIRED / INACTIVE', style: AppText.eyebrow()),
              const SizedBox(height: 12),
              for (final promo in expiredPromos) ...[
                _PromoCard(
                  promo: promo,
                  onToggle: () => notifier.togglePromoActive(promo.id),
                  onDelete: () => notifier.deletePromo(promo.id),
                  expired: true,
                ),
                const SizedBox(height: 10),
              ],
            ],
            if (activePromos.isEmpty && expiredPromos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.local_offer_outlined, size: 48, color: AppColors.muted.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'No promos yet',
                        style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create your first promotion to attract customers',
                        style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
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

  void _showPromoFormSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PromoFormSheet(),
    );
  }
}

class _CreatePromoButton extends StatelessWidget {
  const _CreatePromoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.teal,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Create Promo',
                style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.promo,
    required this.onToggle,
    required this.onDelete,
    this.expired = false,
  });

  final PromoOffer promo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: expired ? Colors.white.withValues(alpha: 0.5) : Colors.white,
        border: Border.all(color: expired ? AppColors.creamDark.withValues(alpha: 0.5) : AppColors.creamDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: expired ? AppColors.creamDark : AppColors.tealMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promo.discountLabel,
                  style: AppText.sans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: expired ? AppColors.muted : AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  promo.code,
                  style: AppText.sans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (!expired)
                SizedBox(
                  height: 28,
                  child: Switch(
                    value: promo.isActive,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: AppColors.teal,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            promo.title,
            style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.slate),
          ),
          const SizedBox(height: 4),
          Text(
            promo.description,
            style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _PromoStat(
                icon: Icons.redeem_outlined,
                label: '${promo.currentRedemptions}${promo.maxRedemptions != null ? '/${promo.maxRedemptions}' : ''} used',
              ),
              const SizedBox(width: 16),
              _PromoStat(
                icon: Icons.schedule_outlined,
                label: promo.isExpired ? 'Expired' : promo.countdownLabel,
              ),
              const SizedBox(width: 16),
              _PromoStat(
                icon: Icons.people_outline,
                label: promo.audienceLabel,
              ),
            ],
          ),
          if (expired) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  promo.isExpired ? 'Expired' : 'Inactive',
                  style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onDelete,
                  child: Text(
                    'Delete',
                    style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PromoStat extends StatelessWidget {
  const _PromoStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
      ],
    );
  }
}

class PromoFormSheet extends ConsumerStatefulWidget {
  const PromoFormSheet({super.key});

  @override
  ConsumerState<PromoFormSheet> createState() => _PromoFormSheetState();
}

class _PromoFormSheetState extends ConsumerState<PromoFormSheet> {
  final _nameController = TextEditingController();
  final _discountController = TextEditingController();
  final _minSpendController = TextEditingController();
  final _maxRedemptionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(categoriesProvider).items.isEmpty) {
        ref.read(categoriesProvider.notifier).load(withItems: true);
      }
      if (ref.read(vendorPackagesProvider).isEmpty) {
        ref.read(vendorPackagesProvider.notifier).loadPackages();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _discountController.dispose();
    _minSpendController.dispose();
    _maxRedemptionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorPromosProvider);
    final notifier = ref.read(vendorPromosProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.creamDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Create Promo', style: AppText.serif(fontSize: 24)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.slate),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              children: [
                _FormLabel('PROMO NAME'),
                _FormTextField(
                  controller: _nameController,
                  hint: 'e.g., 15% Off Suits',
                  onChanged: notifier.setPromoName,
                ),
                const SizedBox(height: 16),
                _FormLabel('DISCOUNT TYPE'),
                Row(
                  children: [
                    _FormChip(
                      label: 'Percentage (%)',
                      selected: state.selectedDiscountType == 0,
                      onTap: () => notifier.pickDiscountType(0),
                    ),
                    const SizedBox(width: 10),
                    _FormChip(
                      label: 'Fixed Amount (TZS)',
                      selected: state.selectedDiscountType == 1,
                      onTap: () => notifier.pickDiscountType(1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormLabel(state.selectedDiscountType == 0 ? 'PERCENTAGE' : 'AMOUNT (TZS)'),
                _FormTextField(
                  controller: _discountController,
                  hint: state.selectedDiscountType == 0 ? 'e.g., 15' : 'e.g., 5000',
                  keyboardType: TextInputType.number,
                  onChanged: notifier.setDiscountValue,
                ),
                const SizedBox(height: 16),
                _FormLabel('APPLIES TO'),
                Row(
                  children: [
                    _FormChip(
                      label: 'Entire Order',
                      selected: state.selectedAppliesTo == 0,
                      onTap: () => notifier.pickAppliesTo(0),
                    ),
                    const SizedBox(width: 10),
                    _FormChip(
                      label: 'Category',
                      selected: state.selectedAppliesTo == 1,
                      onTap: () => notifier.pickAppliesTo(1),
                    ),
                    const SizedBox(width: 10),
                    _FormChip(
                      label: 'Item',
                      selected: state.selectedAppliesTo == 2,
                      onTap: () => notifier.pickAppliesTo(2),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _FormChip(
                      label: 'Package',
                      selected: state.selectedAppliesTo == 3,
                      onTap: () => notifier.pickAppliesTo(3),
                    ),
                    const SizedBox(width: 10),
                    _FormChip(
                      label: 'Delivery',
                      selected: state.selectedAppliesTo == 4,
                      onTap: () => notifier.pickAppliesTo(4),
                    ),
                    const SizedBox(width: 10),
                    const Spacer(),
                  ],
                ),
                if (state.selectedAppliesTo == 1) ...[
                  const SizedBox(height: 12),
                  _FormLabel('CATEGORY'),
                  _PickerRow(
                    label: state.targetCategoryName,
                    hint: 'Select a category',
                    onTap: () async {
                      final picked = await _pickCategory(context, ref);
                      if (picked != null) notifier.pickTargetCategory(picked.$1, picked.$2);
                    },
                  ),
                ],
                if (state.selectedAppliesTo == 2) ...[
                  const SizedBox(height: 12),
                  _FormLabel('ITEM'),
                  _PickerRow(
                    label: state.targetItemName,
                    hint: 'Select an item',
                    onTap: () async {
                      final picked = await _pickItem(context, ref);
                      if (picked != null) notifier.pickTargetItem(picked.$1, picked.$2);
                    },
                  ),
                ],
                if (state.selectedAppliesTo == 3) ...[
                  const SizedBox(height: 12),
                  _FormLabel('PACKAGE'),
                  _PickerRow(
                    label: state.targetPackageName,
                    hint: 'Select a package',
                    onTap: () async {
                      final picked = await _pickPackage(context, ref);
                      if (picked != null) notifier.pickTargetPackage(picked.$1, picked.$2);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                _FormLabel('MINIMUM SPEND (OPTIONAL)'),
                _FormTextField(
                  controller: _minSpendController,
                  hint: 'e.g., 20000',
                  keyboardType: TextInputType.number,
                  onChanged: notifier.setMinSpend,
                ),
                const SizedBox(height: 16),
                _FormLabel('TARGET AUDIENCE'),
                Row(
                  children: [
                    _FormChip(
                      label: 'All Users',
                      selected: state.selectedAudience == 0,
                      onTap: () => notifier.pickAudience(0),
                    ),
                    const SizedBox(width: 10),
                    _FormChip(
                      label: 'First-time',
                      selected: state.selectedAudience == 1,
                      onTap: () => notifier.pickAudience(1),
                    ),
                    const SizedBox(width: 10),
                    _FormChip(
                      label: 'Returning',
                      selected: state.selectedAudience == 2,
                      onTap: () => notifier.pickAudience(2),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormLabel('MAX REDEMPTIONS (OPTIONAL)'),
                _FormTextField(
                  controller: _maxRedemptionsController,
                  hint: 'e.g., 100',
                  keyboardType: TextInputType.number,
                  onChanged: notifier.setMaxRedemptions,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Start Date',
                        date: state.startDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: state.startDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) notifier.setStartDate(date);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'End Date',
                        date: state.endDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: state.endDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) notifier.setEndDate(date);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () async {
                        if (!notifier.canSubmit) {
                          final needsTarget = (state.selectedAppliesTo == 1 && state.targetCategoryId == null) ||
                              (state.selectedAppliesTo == 2 && state.targetItemId == null) ||
                              (state.selectedAppliesTo == 3 && state.targetPackageId == null);
                          final targetLabel = switch (state.selectedAppliesTo) {
                            1 => 'category',
                            2 => 'item',
                            3 => 'package',
                            _ => '',
                          };
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                needsTarget
                                    ? 'Pick a $targetLabel for this promo.'
                                    : 'Enter a promo name and discount value.',
                              ),
                            ),
                          );
                          return;
                        }
                        // Wait for the actual result instead of popping
                        // unconditionally — otherwise a failed create looks
                        // identical to a successful one.
                        final ok = await notifier.createPromo();
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not create promo. Please try again.')),
                          );
                        }
                      },
                      child: Center(
                        child: Text(
                          'Create Promo',
                          style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
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
    );
  }
}

/// Opens a single-select category picker, returning the chosen (id, name),
/// or null if the vendor backed out. Sourced from the shop's real catalog —
/// the backend only accepts a `target_category_id` matching an existing row.
Future<(String, String)?> _pickCategory(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Consumer(builder: (_, ref, _) {
      return _TargetPickerSheet(
        title: 'Select category',
        subtitle: 'Choose which category this promo applies to.',
        categories: ref.watch(categoriesProvider).items,
        mode: _TargetPickerMode.category,
      );
    }),
  );
}

/// Same as [_pickCategory] but for a single item, grouped by category.
Future<(String, String)?> _pickItem(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Consumer(builder: (_, ref, _) {
      return _TargetPickerSheet(
        title: 'Select item',
        subtitle: 'Choose which item this promo applies to.',
        categories: ref.watch(categoriesProvider).items,
        mode: _TargetPickerMode.item,
      );
    }),
  );
}

/// Single-select picker over the vendor's own packages, returning the chosen
/// (id, name), or null if the vendor backed out. Sourced from
/// `vendorPackagesProvider` — the backend only accepts a `target_package_id`
/// matching an existing row owned by this vendor.
Future<(String, String)?> _pickPackage(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Consumer(builder: (_, ref, _) {
      return _PackagePickerSheet(packages: ref.watch(vendorPackagesProvider));
    }),
  );
}

class _PackagePickerSheet extends StatelessWidget {
  const _PackagePickerSheet({required this.packages});
  final List<ServicePackage> packages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFDED8CA), borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                Text('Select package', style: AppText.serif(fontSize: 22)),
                const SizedBox(height: 3),
                Text('Choose which package this promo applies to.', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: 14),
                if (packages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No packages yet.',
                        style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  ...packages.map((pkg) => _PickerTile(
                    title: pkg.name,
                    subtitle: formatMoney(pkg.priceTzs),
                    onTap: () => Navigator.of(context).pop((pkg.id, pkg.name)),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _TargetPickerMode { category, item }

/// Single-select sheet listing the shop's real categories/items, styled
/// after the package form's item picker. Tapping a row selects it and
/// closes the sheet immediately — there's nothing else to configure here.
class _TargetPickerSheet extends StatelessWidget {
  const _TargetPickerSheet({
    required this.title,
    required this.subtitle,
    required this.categories,
    required this.mode,
  });

  final String title;
  final String subtitle;
  final List<LaundryCategory> categories;
  final _TargetPickerMode mode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFDED8CA), borderRadius: BorderRadius.circular(99)),
                  ),
                ),
                Text(title, style: AppText.serif(fontSize: 22)),
                const SizedBox(height: 3),
                Text(subtitle, style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                const SizedBox(height: 14),
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No catalog items yet.',
                        style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                      ),
                    ),
                  )
                else if (mode == _TargetPickerMode.category)
                  ...categories.map((cat) => _PickerTile(
                    title: cat.name,
                    subtitle: '${cat.items.length} items',
                    onTap: () => Navigator.of(context).pop((cat.id, cat.name)),
                  ))
                else
                  ...categories.map((cat) => cat.items.isEmpty
                      ? const SizedBox.shrink()
                      : _ItemPickerSection(category: cat)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemPickerSection extends StatelessWidget {
  const _ItemPickerSection({required this.category});
  final LaundryCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.creamDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text(category.name, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700)),
          subtitle: Text('${category.items.length} items', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
          children: category.items
              .map((item) => _PickerTile(
                    title: item.name,
                    subtitle: item.description,
                    onTap: () => Navigator.of(context).pop((item.id, item.name)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cream))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

/// Read-only field styled like [_FormTextField] that opens a picker instead
/// of accepting typed text — shows the picked name, or [hint] when nothing
/// is selected yet.
class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.label, required this.hint, required this.onTap});
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = label.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.creamDark),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? label : hint,
                style: AppText.sans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: hasValue ? AppColors.slate : AppColors.muted,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), style: AppText.eyebrow()),
    );
  }
}

class _FormTextField extends StatelessWidget {
  const _FormTextField({
    this.controller,
    this.hint,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
        ),
      ),
    );
  }
}

class _FormChip extends StatelessWidget {
  const _FormChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected ? AppColors.tealMuted : Colors.white,
            border: Border.all(
              color: selected ? AppColors.teal : AppColors.creamDark,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.sans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.teal : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.creamDark),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          date != null ? '${date!.month}/${date!.day}/${date!.year}' : label,
          style: AppText.sans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: date != null ? AppColors.slate : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
