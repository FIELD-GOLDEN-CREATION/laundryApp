import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/promo_offer.dart';
import '../../state/vendor_promos_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class VendorPromosScreen extends ConsumerWidget {
  const VendorPromosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                if (state.selectedAppliesTo == 1) ...[
                  const SizedBox(height: 12),
                  _FormLabel('CATEGORY'),
                  _FormTextField(
                    hint: 'e.g., Formal, Woolen & Outerwear',
                    onChanged: notifier.setTargetCategory,
                  ),
                ],
                if (state.selectedAppliesTo == 2) ...[
                  const SizedBox(height: 12),
                  _FormLabel('ITEM'),
                  _FormTextField(
                    hint: 'e.g., 2-Piece Suit',
                    onChanged: notifier.setTargetItem,
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
                      onTap: () {
                        if (_nameController.text.isNotEmpty && _discountController.text.isNotEmpty) {
                          notifier.createPromo();
                          Navigator.pop(context);
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
