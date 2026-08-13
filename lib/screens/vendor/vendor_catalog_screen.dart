import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/vendor_mock_data.dart';
import '../../state/vendor_catalog_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';
import '../../widgets/selectable_chip.dart';
import '../../widgets/toggle_switch.dart';

class VendorCatalogScreen extends ConsumerWidget {
  const VendorCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorCatalogProvider);
    final notifier = ref.read(vendorCatalogProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Services & pricing', style: AppText.serif(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Changes go live on your shop page straight away.',
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const _SectionLabel('Categories offered'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < kCategoryLabels.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: i == kCategoryLabels.length - 1 ? Colors.transparent : AppColors.cream),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              kCategoryLabels[i],
                              style: AppText.sans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: state.categoriesOn[i] ? AppColors.slate : AppColors.muted,
                              ),
                            ),
                          ),
                          ToggleSwitch(on: state.categoriesOn[i], onTap: () => notifier.toggleCategory(i)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const _SectionLabel('Menu pricing'),
            Column(
              children: [
                for (var i = 0; i < kMenuPriceRows.length; i++) ...[
                  _PriceRow(
                    name: kMenuPriceRows[i].name,
                    unit: kMenuPriceRows[i].unit,
                    price: state.prices[kMenuPriceRows[i].key] ?? 0,
                    onInc: () => notifier.adjustPrice(kMenuPriceRows[i].key, 500),
                    onDec: () => notifier.adjustPrice(kMenuPriceRows[i].key, -500),
                  ),
                  if (i != kMenuPriceRows.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
            const _SectionLabel('Turnaround offered'),
            Row(
              children: [
                for (var i = 0; i < kTurnaroundOptions.length; i++) ...[
                  if (i != 0) const SizedBox(width: 10),
                  Expanded(
                    child: SelectableChip(
                      label: kTurnaroundOptions[i].label,
                      sub: kTurnaroundOptions[i].sub,
                      selected: state.turnaround == i,
                      onTap: () => notifier.pickTurnaround(i),
                      variant: ChipVariant.muted,
                      borderRadius: 16,
                      fontSize: 15,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ],
            ),
            const _SectionLabel('Add-ons & upsells'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < kAddonToggles.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: i == kAddonToggles.length - 1 ? Colors.transparent : AppColors.cream),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(kAddonToggles[i].label, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 3),
                                Text(
                                  kAddonToggles[i].price,
                                  style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.amber),
                                ),
                              ],
                            ),
                          ),
                          ToggleSwitch(on: state.addonsOn[i], onTap: () => notifier.toggleAddon(i)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 11),
      child: Text(text.toUpperCase(), style: AppText.eyebrow()),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.name, required this.unit, required this.price, required this.onInc, required this.onDec});

  final String name;
  final String unit;
  final double price;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(unit, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
              ],
            ),
          ),
          Text(
            formatTzs(price),
            style: AppText.serif(fontSize: 19, color: AppColors.teal),
          ),
          const SizedBox(width: 10),
          _StepButton(symbol: '−', bg: AppColors.cream, fg: AppColors.teal, border: true, onTap: onDec),
          const SizedBox(width: 6),
          _StepButton(symbol: '+', bg: AppColors.teal, fg: Colors.white, border: false, onTap: onInc),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.symbol, required this.bg, required this.fg, required this.border, required this.onTap});

  final String symbol;
  final Color bg;
  final Color fg;
  final bool border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: border ? const BorderSide(color: AppColors.creamDark) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: Text(symbol, style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w800, height: 1)),
          ),
        ),
      ),
    );
  }
}
