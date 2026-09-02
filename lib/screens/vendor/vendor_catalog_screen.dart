import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/laundry_category.dart';
import '../../models/service_package.dart';
import '../../state/catalog_state.dart';
import '../../state/vendor_catalog_state.dart';
import '../../state/vendor_packages_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/currency.dart';
import '../../widgets/package_form_sheet.dart';
import '../../widgets/toggle_switch.dart';
import '../../widgets/remote_image.dart';

/// Display cap mirrored from the shop page's package carousel.
const _kMaxShopPackages = 4;

class VendorCatalogScreen extends ConsumerStatefulWidget {
  const VendorCatalogScreen({super.key});

  @override
  ConsumerState<VendorCatalogScreen> createState() => _VendorCatalogScreenState();
}

class _VendorCatalogScreenState extends ConsumerState<VendorCatalogScreen> {
  @override
  void initState() {
    super.initState();
    // Global catalog gives the structure; /vendor/catalog overlays the
    // vendor's own prices and availability on top of it.
    Future.microtask(() {
      ref.read(categoriesProvider.notifier).load(withItems: true);
      ref.read(vendorCatalogProvider.notifier).loadCatalog();
      ref.read(vendorPackagesProvider.notifier).loadPackages();
      ref.read(vendorCatalogProvider.notifier).loadAddons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorCatalogProvider);
    final notifier = ref.read(vendorCatalogProvider.notifier);
    final packages = ref.watch(vendorPackagesProvider);
    final packagesNotifier = ref.read(vendorPackagesProvider.notifier);
    final categories = ref.watch(categoriesProvider);
    final liveCount = packages.where((p) => p.active).length;
    final displayedCount = liveCount < _kMaxShopPackages ? liveCount : _kMaxShopPackages;

    if (categories.items.isEmpty && categories.isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Services & pricing', style: AppText.serif(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              'Select categories and items you offer. Changes go live on your shop page straight away.',
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const _SectionLabel('Categories & Items'),
            ...List.generate(categories.items.length, (i) {
              final category = categories.items[i];
              return _CategoryExpansionTile(
                category: category,
                isCategoryOn: notifier.isCategoryEnabled(category.id),
                onToggleCategory: () => notifier.toggleCategory(category.id),
                items: category.items,
                notifier: notifier,
                categoryId: category.id,
              );
            }),
            const _SectionLabel('Add-on services'),
            Text(
              'Define extra services customers can add to their order at checkout.',
              style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.3),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < state.addons.length; i++)
                    _AddonRow(
                      addon: state.addons[i],
                      onRemove: () => notifier.removeAddon(i),
                      onUpdated: (title, price) => notifier.updateAddon(i, title: title, priceTzs: price),
                    ),
                  _AddAddonRow(
                    onAdd: (title, price) => notifier.addAddon(title, price),
                  ),
                ],
              ),
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
                    if (created != null) packagesNotifier.createPackage(created);
                  },
                ),
              ],
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

class _CategoryExpansionTile extends StatelessWidget {
  const _CategoryExpansionTile({
    required this.category,
    required this.isCategoryOn,
    required this.onToggleCategory,
    required this.items,
    required this.notifier,
    required this.categoryId,
  });

  final LaundryCategory category;
  final bool isCategoryOn;
  final VoidCallback onToggleCategory;
  final List<LaundryItem> items;
  final VendorCatalogNotifier notifier;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.creamDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 50,
            height: 50,
            child: RemoteImage(
              url: category.imageUrl,
              fallback: category.name,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          category.name,
          style: AppText.sans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isCategoryOn ? AppColors.slate : AppColors.muted,
          ),
        ),
        subtitle: Text(
          '${items.length} items',
          style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        trailing: ToggleSwitch(on: isCategoryOn, onTap: onToggleCategory),
        children: items.map((item) {
          // Vendor's own price wins; fall back to the global catalog price.
          final vendorPrice = notifier.effectiveItemPrice(item.id);
          return _ItemCheckboxRow(
            item: item,
            isChecked: notifier.isItemEnabled(categoryId, item.id),
            onToggle: () => notifier.toggleItem(categoryId, item.id, fallbackPrice: item.priceTzs),
            price: vendorPrice > 0 ? vendorPrice : item.priceTzs,
            onPriceChanged: (price) => notifier.setItemPrice(item.id, price),
          );
        }).toList(),
      ),
        ),
    );
  }
}

class _ItemCheckboxRow extends StatefulWidget {
  const _ItemCheckboxRow({
    required this.item,
    required this.isChecked,
    required this.onToggle,
    required this.price,
    required this.onPriceChanged,
  });

  final LaundryItem item;
  final bool isChecked;
  final VoidCallback onToggle;
  final double price;
  final ValueChanged<double> onPriceChanged;

  @override
  State<_ItemCheckboxRow> createState() => _ItemCheckboxRowState();
}

class _ItemCheckboxRowState extends State<_ItemCheckboxRow> {
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
    if (value != null) widget.onPriceChanged(value);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: widget.isChecked,
                  onChanged: (_) => widget.onToggle(),
                  activeColor: AppColors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: RemoteImage(
                    url: widget.item.imageUrl,
                    fallback: widget.item.name.isNotEmpty ? widget.item.name[0].toUpperCase() : '?',
                    borderRadius: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      widget.item.description,
                      style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (!_editing) ...[
                Text(
                  formatTzs(widget.price),
                  style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.teal),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _startEditing,
                  child: Text('Edit', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ),
              ],
            ],
          ),
          if (_editing) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      border: Border.all(color: AppColors.creamDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Price (TZS)',
                        hintStyle: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _cancel,
                  child: Text('Cancel', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _save,
                  child: Text('Save', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ),
              ],
            ),
          ],
        ],
      ),
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

class _AddonRow extends StatefulWidget {
  const _AddonRow({required this.addon, required this.onRemove, required this.onUpdated});
  final VendorAddon addon;
  final VoidCallback onRemove;
  final void Function(String title, double priceTzs) onUpdated;

  @override
  State<_AddonRow> createState() => _AddonRowState();
}

class _AddonRowState extends State<_AddonRow> {
  bool _editing = false;
  late final _titleCtrl = TextEditingController(text: widget.addon.title);
  late final _priceCtrl = TextEditingController(text: widget.addon.priceTzs.round().toString());

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (title.isNotEmpty && price > 0) {
      widget.onUpdated(title, price);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cream))),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _titleCtrl,
                      autofocus: true,
                      style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Service name',
                        hintStyle: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 110,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700),
                    decoration: InputDecoration.collapsed(
                      hintText: 'TZS',
                      hintStyle: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _editing = false),
                  child: Text('Cancel', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _save,
                  child: Text('Save', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cream))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.addon.title, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(formatTzs(widget.addon.priceTzs), style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.amber)),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _editing = true),
            child: Text('Edit', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
          ),
          const SizedBox(width: 12),
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
    );
  }
}

class _AddAddonRow extends StatefulWidget {
  const _AddAddonRow({required this.onAdd});
  final void Function(String title, double priceTzs) onAdd;

  @override
  State<_AddAddonRow> createState() => _AddAddonRowState();
}

class _AddAddonRowState extends State<_AddAddonRow> {
  bool _expanded = false;
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _add() {
    final title = _titleCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (title.isNotEmpty && price > 0) {
      widget.onAdd(title, price);
      _titleCtrl.clear();
      _priceCtrl.clear();
      setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = true),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            child: Center(
              child: Text('+ Add service', style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.cream))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: _titleCtrl,
                    autofocus: true,
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700),
                    decoration: InputDecoration.collapsed(
                      hintText: 'Service name (e.g. Express delivery)',
                      hintStyle: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 110,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700),
                  decoration: InputDecoration.collapsed(
                    hintText: 'TZS',
                    hintStyle: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: Text('Cancel', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _add,
                child: Text('Add', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

