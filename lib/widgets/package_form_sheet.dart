import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/laundry_category.dart';
import '../models/service_package.dart';
import '../state/catalog_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../utils/currency.dart';
import 'selectable_chip.dart';

/// "New package" composer for the Vendor Catalog screen. Returns the built
/// [ServicePackage], or null if the vendor backed out.
///
/// Styled after `showCrudFormModal` — cream sheet, grabber, eyebrow-labelled
/// fields, Cancel + primary pair — but it actually returns a value, because
/// unlike the admin modals this one writes to real state.
Future<ServicePackage?> showPackageFormSheet(BuildContext context) {
  return showModalBottomSheet<ServicePackage>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _PackageForm(),
  );
}

/// A StatefulWidget rather than a `StatefulBuilder` + controllers captured in
/// the closure: the sheet keeps rebuilding through its exit animation, well
/// after `showModalBottomSheet`'s future resolves, so controllers disposed
/// alongside that future get used after disposal. Owning them here ties
/// their lifetime to the subtree that actually reads them.
class _PackageForm extends ConsumerStatefulWidget {
  const _PackageForm();

  @override
  ConsumerState<_PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends ConsumerState<_PackageForm> {
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _price = TextEditingController();
  final _unit = TextEditingController(text: 'bag');
  final _note = TextEditingController();

  PackageKind _kind = PackageKind.weight;
  List<String> _inclusions = [];
  final Map<String, int> _packageItemQty = {}; // itemId -> qty

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(categoriesProvider).items.isEmpty) {
        ref.read(categoriesProvider.notifier).load(withItems: true);
      }
    });
  }

  @override
  void dispose() {
    for (final controller in [_name, _tagline, _price, _unit, _note]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Every catalog item across categories — the live replacement for the
  /// old static menu-price rows.
  List<LaundryItem> get _allItems =>
      ref.watch(categoriesProvider).items.expand((c) => c.items).toList();

  LaundryItem? _itemById(String itemId) {
    for (final item in _allItems) {
      if (item.id == itemId) return item;
    }
    return null;
  }

  double get _priceTzs => double.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  bool get _valid => _name.text.trim().isNotEmpty && _priceTzs > 0;

  void _save() {
    final unit = _unit.text.trim();
    // Build package items from selected items with quantities
    final packageItems = <PackageItem>[];
    for (final entry in _packageItemQty.entries) {
      if (entry.value > 0) {
        final item = _itemById(entry.key);
        if (item != null) {
          packageItems.add(PackageItem(
            itemId: item.id,
            itemName: item.name,
            qty: entry.value,
            unitPrice: item.priceTzs,
          ));
        }
      }
    }
    Navigator.of(context).pop(
      ServicePackage(
        id: 'vendor-${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        tagline: _tagline.text.trim(),
        kind: _kind,
        priceTzs: _priceTzs,
        priceUnit: unit.isEmpty ? '/ package' : '/ $unit',
        inclusions: _inclusions,
        note: _note.text.trim(),
        packageItems: packageItems,
      ),
    );
  }

  Future<void> _pickInclusions() async {
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Consumer(builder: (_, ref, _) {
        final names = [
          for (final item in ref.watch(categoriesProvider).items.expand((c) => c.items))
            if (item.name.isNotEmpty) item.name,
        ];
        return _InclusionsSheet(selected: _inclusions, options: names.toSet().toList());
      }),
    );
    if (picked != null) setState(() => _inclusions = picked);
  }

  Future<void> _pickPackageItems() async {
    final picked = await showModalBottomSheet<Map<String, int>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Consumer(builder: (_, ref, _) {
        return _PackageItemsSheet(
          selected: Map.of(_packageItemQty),
          categories: ref.watch(categoriesProvider).items,
        );
      }),
    );
    if (picked != null) {
      setState(() => _packageItemQty
        ..clear()
        ..addAll(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
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
              Text('New package', style: AppText.serif(fontSize: 22)),
              const SizedBox(height: 3),
              Text(
                'Goes live on your shop page as soon as you save it.',
                style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              Text('PACKAGE TYPE', style: AppText.eyebrow()),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final option in PackageKind.values)
                    SelectableChip(
                      label: _kindChipLabel(option),
                      selected: _kind == option,
                      onTap: () => setState(() => _kind = option),
                      variant: ChipVariant.muted,
                      borderRadius: 12,
                      fontSize: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _Field(label: 'PACKAGE NAME', hint: 'e.g. The Student Bag', controller: _name, onChanged: _rebuild),
              const SizedBox(height: 12),
              _Field(label: 'TAGLINE', hint: 'e.g. Up to 5kg of everyday wear', controller: _tagline, onChanged: _rebuild),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _Field(label: 'PRICE (TZS)', hint: '34000', controller: _price, digitsOnly: true, onChanged: _rebuild),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _Field(label: 'PER', hint: 'bag', controller: _unit, onChanged: _rebuild),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('PACKAGE ITEMS', style: AppText.eyebrow()),
              const SizedBox(height: 7),
              Text(
                'Select items and quantities for this package. Any items not included will use normal basket pricing.',
                style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.3),
              ),
              const SizedBox(height: 7),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.creamDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _pickPackageItems,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _packageItemQty.isEmpty
                                ? 'Select items for this package'
                                : '${_packageItemQty.values.where((q) => q > 0).length} items selected',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _packageItemQty.isEmpty ? AppColors.muted : AppColors.slate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
              if (_packageItemQty.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in _packageItemQty.entries)
                      if (entry.value > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.tealMuted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.value}× ${_itemById(entry.key)?.name ?? entry.key}',
                            style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal),
                          ),
                        ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text('INCLUDES', style: AppText.eyebrow()),
              const SizedBox(height: 7),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.creamDark),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _pickInclusions,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _inclusions.isEmpty ? 'Select from your menu pricing' : _inclusions.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.sans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _inclusions.isEmpty ? AppColors.muted : AppColors.slate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Field(label: 'FINE PRINT (OPTIONAL)', hint: 'e.g. Fits up to King size', controller: _note, onChanged: _rebuild),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          child: Text('Cancel', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 7,
                    child: Material(
                      // A package with no name or no price cannot be sold, so
                      // the primary stays inert until both land.
                      color: _valid ? AppColors.teal : AppColors.creamDark,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _valid ? _save : null,
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          child: Text(
                            'Save package',
                            style: AppText.sans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _valid ? AppColors.cream : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _rebuild() => setState(() {});
}

String _kindChipLabel(PackageKind kind) => switch (kind) {
  PackageKind.weight => 'By weight',
  PackageKind.itemCount => 'By item count',
  PackageKind.household => 'Household',
  PackageKind.subscription => 'Subscription',
};

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.digitsOnly = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool digitsOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.eyebrow()),
        const SizedBox(height: 7),
        Container(
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
            onChanged: (_) => onChanged(),
            keyboardType: digitsOnly ? TextInputType.number : TextInputType.text,
            inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
        ),
      ],
    );
  }
}

/// Multi-select checklist for a package's inclusions — sourced from the
/// live catalog items rather than free text, so a package can never claim
/// to include a service the vendor doesn't actually offer.
class _InclusionsSheet extends StatefulWidget {
  const _InclusionsSheet({required this.selected, required this.options});

  final List<String> selected;
  final List<String> options;

  @override
  State<_InclusionsSheet> createState() => _InclusionsSheetState();
}

class _InclusionsSheetState extends State<_InclusionsSheet> {
  late final Set<String> _picked = Set.of(widget.selected);

  void _toggle(String name) => setState(() {
    if (!_picked.remove(name)) _picked.add(name);
  });

  void _done() {
    Navigator.of(context).pop([
      for (final name in widget.options)
        if (_picked.contains(name)) name,
    ]);
  }

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
                Text('Includes', style: AppText.serif(fontSize: 22)),
                const SizedBox(height: 3),
                 Text(
                   'Pick from the services in your catalog.',
                   style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                 ),
                 const SizedBox(height: 14),
                 widget.options.isEmpty
                     ? Padding(
                         padding: const EdgeInsets.symmetric(vertical: 24),
                         child: Center(
                           child: Text(
                             'No catalog items yet.',
                             style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                           ),
                         ),
                       )
                     : Container(
                         decoration: BoxDecoration(
                           color: Colors.white,
                           border: Border.all(color: AppColors.creamDark),
                           borderRadius: BorderRadius.circular(18),
                         ),
                         clipBehavior: Clip.antiAlias,
                         child: Column(
                           children: [
                             for (var i = 0; i < widget.options.length; i++)
                               Material(
                                 color: Colors.transparent,
                                 child: InkWell(
                                   onTap: () => _toggle(widget.options[i]),
                                   child: Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                     decoration: BoxDecoration(
                                       border: Border(
                                         bottom: BorderSide(
                                           color: i == widget.options.length - 1 ? Colors.transparent : AppColors.cream,
                                         ),
                                       ),
                                     ),
                                     child: Row(
                                       children: [
                                         _InclusionCheckbox(checked: _picked.contains(widget.options[i])),
                                         const SizedBox(width: 12),
                                         Expanded(
                                           child: Text(
                                             widget.options[i],
                                             style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),
                               ),
                           ],
                         ),
                       ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _done,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: Text('Done', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InclusionCheckbox extends StatelessWidget {
  const _InclusionCheckbox({required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AppColors.teal : Colors.transparent,
        border: Border.all(color: checked ? AppColors.teal : const Color(0xFFCBD5CF), width: 2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: checked ? const Icon(Icons.check, size: 14, color: AppColors.cream) : null,
    );
  }
}

/// Multi-select sheet for picking items with quantities for a package.
/// Each item shows a stepper (+/−) so the vendor can set how many of each
/// garment goes into the bundle. Items come from the live catalog provider.
class _PackageItemsSheet extends StatefulWidget {
  const _PackageItemsSheet({required this.selected, required this.categories});
  final Map<String, int> selected;
  final List<LaundryCategory> categories;

  @override
  State<_PackageItemsSheet> createState() => _PackageItemsSheetState();
}

class _PackageItemsSheetState extends State<_PackageItemsSheet> {
  late final Map<String, int> _qty;

  @override
  void initState() {
    super.initState();
    _qty = Map.of(widget.selected);
  }

  void _setQty(String itemId, int delta) {
    setState(() {
      _qty[itemId] = ((_qty[itemId] ?? 0) + delta).clamp(0, 99);
    });
  }

  void _done() {
    // Only return items with qty > 0
    final result = <String, int>{};
    for (final entry in _qty.entries) {
      if (entry.value > 0) result[entry.key] = entry.value;
    }
    Navigator.of(context).pop(result);
  }

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
                Text('Package Items', style: AppText.serif(fontSize: 22)),
                 const SizedBox(height: 3),
                 Text(
                   'Select items and set quantities for this package.',
                   style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                 ),
                 const SizedBox(height: 14),
                 if (widget.categories.isEmpty)
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 24),
                     child: Center(
                       child: Text(
                         'No catalog items yet.',
                         style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                       ),
                     ),
                   )
                 else
                   ...widget.categories.map((cat) => _CategorySection(
                     category: cat,
                     qty: _qty,
                     onSetQty: _setQty,
                   )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _done,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: Text('Done', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.qty, required this.onSetQty});
  final LaundryCategory category;
  final Map<String, int> qty;
  final void Function(String itemId, int delta) onSetQty;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(category.name, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700)),
        subtitle: Text('${category.items.length} items', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted)),
        children: category.items.map((item) => _ItemQtyRow(
          item: item,
          qty: qty[item.id] ?? 0,
          onIncrement: () => onSetQty(item.id, 1),
          onDecrement: () => onSetQty(item.id, -1),
        )).toList(),
      ),
    );
  }
}

class _ItemQtyRow extends StatelessWidget {
  const _ItemQtyRow({required this.item, required this.qty, required this.onIncrement, required this.onDecrement});
  final LaundryItem item;
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${formatTzs(item.priceTzs)} ${item.unit}',
                  style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ],
            ),
          ),
          if (qty > 0) ...[
            GestureDetector(
              onTap: onDecrement,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.creamDark),
                ),
                alignment: Alignment.center,
                child: const Text('−', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.teal)),
              ),
            ),
            SizedBox(
              width: 32,
              child: Text('$qty', textAlign: TextAlign.center, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ),
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.creamDark),
                ),
                child: Text('Add', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
