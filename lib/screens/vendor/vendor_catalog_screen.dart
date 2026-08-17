import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_data.dart';
import '../../data/vendor_mock_data.dart';
import '../../models/service_package.dart';
import '../../state/vendor_catalog_state.dart';
import '../../state/vendor_packages_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';
import '../../widgets/package_form_sheet.dart';
import '../../widgets/selectable_chip.dart';
import '../../widgets/toggle_switch.dart';

class VendorCatalogScreen extends ConsumerWidget {
  const VendorCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorCatalogProvider);
    final notifier = ref.read(vendorCatalogProvider.notifier);
    final packages = ref.watch(vendorPackagesProvider);
    final packagesNotifier = ref.read(vendorPackagesProvider.notifier);
    final liveCount = packages.where((p) => p.active).length;
    // The customer-facing section caps how many it renders, so say so here
    // rather than letting a vendor wonder where package five went.
    final displayedCount = liveCount < kMaxShopPackages ? liveCount : kMaxShopPackages;

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
                    onSave: (value) => notifier.setPrice(kMenuPriceRows[i].key, value),
                  ),
                  if (i != kMenuPriceRows.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
            const _SectionLabel('Packages'),
            Text(
              liveCount == 0
                  ? 'No packages live — your shop page shows the price list only.'
                  : 'Your shop page shows the first $displayedCount of $liveCount live '
                        '${liveCount == 1 ? 'package' : 'packages'}, above the price list.',
              style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 11),
            Column(
              children: [
                for (final package in packages) ...[
                  _PackageRow(
                    package: package,
                    onToggle: () => packagesNotifier.toggleActive(package.id),
                    onSave: (value) => packagesNotifier.setPrice(package.id, value),
                    onRemove: () => packagesNotifier.removePackage(package.id),
                  ),
                  const SizedBox(height: 10),
                ],
                _AddPackageButton(
                  onTap: () async {
                    final created = await showPackageFormSheet(context);
                    if (created != null) packagesNotifier.addPackage(created);
                  },
                ),
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

class _PriceRow extends StatefulWidget {
  const _PriceRow({required this.name, required this.unit, required this.price, required this.onSave});

  final String name;
  final String unit;
  final double price;
  final ValueChanged<double> onSave;

  @override
  State<_PriceRow> createState() => _PriceRowState();
}

class _PriceRowState extends State<_PriceRow> {
  bool _editing = false;
  late final _controller = TextEditingController(text: widget.price.round().toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() => setState(() => _editing = true);

  void _cancel() {
    _controller.text = widget.price.round().toString();
    setState(() => _editing = false);
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());
    if (value != null) widget.onSave(value);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(widget.unit, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  ],
                ),
              ),
              Text(
                formatTzs(widget.price),
                style: AppText.serif(fontSize: 19, color: AppColors.teal),
              ),
              if (!_editing) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: _startEditing,
                  child: Text('Edit', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ),
              ],
            ],
          ),
          if (_editing) ...[
            const SizedBox(height: 12),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                decoration: InputDecoration.collapsed(
                  hintText: 'Enter price',
                  hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _cancel,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text('Cancel', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _save,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text('Save', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.cream)),
                      ),
                    ),
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

/// A vendor's own bundle: same shell as [_PriceRow] with the extra controls
/// a package needs — a live/paused switch and a remove action. Inactive
/// packages grey out here and vanish from the customer's shop page.
class _PackageRow extends StatefulWidget {
  const _PackageRow({
    required this.package,
    required this.onToggle,
    required this.onSave,
    required this.onRemove,
  });

  final ServicePackage package;
  final VoidCallback onToggle;
  final ValueChanged<double> onSave;
  final VoidCallback onRemove;

  @override
  State<_PackageRow> createState() => _PackageRowState();
}

class _PackageRowState extends State<_PackageRow> {
  bool _editing = false;
  late final _controller = TextEditingController(text: widget.package.priceTzs.round().toString());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() => setState(() => _editing = true);

  void _cancel() {
    _controller.text = widget.package.priceTzs.round().toString();
    setState(() => _editing = false);
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());
    if (value != null) widget.onSave(value);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final package = widget.package;
    final on = package.active;
    final savings = package.savingsPercent;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: on ? AppColors.slate : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${package.kindLabel} · ${package.inclusions.length} '
                      '${package.inclusions.length == 1 ? 'inclusion' : 'inclusions'}',
                      style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              ToggleSwitch(on: on, onTap: widget.onToggle),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              // Price, unit and savings share whatever the Edit link and
              // delete icon leave, wrapping to a second line instead of
              // squeezing the price.
              Expanded(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatTzs(package.priceTzs),
                          style: AppText.serif(fontSize: 19, color: on ? AppColors.teal : AppColors.muted),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          package.unitLabel,
                          style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                        ),
                      ],
                    ),
                    if (savings != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          'Save $savings%',
                          style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                        ),
                      ),
                  ],
                ),
              ),
              if (!_editing) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _startEditing,
                  child: Text('Edit', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ),
              ],
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: widget.onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.danger),
                  ),
                ),
              ),
            ],
          ),
          if (_editing) ...[
            const SizedBox(height: 12),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                decoration: InputDecoration.collapsed(
                  hintText: 'Enter price',
                  hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _cancel,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text('Cancel', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _save,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text('Save', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.cream)),
                      ),
                    ),
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

/// Dashed-intent "add" affordance, matching the customer cart's "+ Add more
/// items" outline button rather than inventing a third button style.
class _AddPackageButton extends StatelessWidget {
  const _AddPackageButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.55), width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              '+ Add package',
              style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.teal),
            ),
          ),
        ),
      ),
    );
  }
}

