import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/service_package.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
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
class _PackageForm extends StatefulWidget {
  const _PackageForm();

  @override
  State<_PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends State<_PackageForm> {
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _price = TextEditingController();
  final _unit = TextEditingController(text: 'bag');
  final _inclusions = TextEditingController();
  final _note = TextEditingController();

  PackageKind _kind = PackageKind.weight;

  @override
  void dispose() {
    for (final controller in [_name, _tagline, _price, _unit, _inclusions, _note]) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _priceTzs => double.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  bool get _valid => _name.text.trim().isNotEmpty && _priceTzs > 0;

  void _save() {
    final unit = _unit.text.trim();
    Navigator.of(context).pop(
      ServicePackage(
        // Vendor-authored packages are runtime-only, so a timestamp keeps
        // them distinct from each other and from the seeded slugs.
        id: 'vendor-${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        tagline: _tagline.text.trim(),
        kind: _kind,
        priceTzs: _priceTzs,
        priceUnit: unit.isEmpty ? '/ package' : '/ $unit',
        inclusions: [
          for (final part in _inclusions.text.split(','))
            if (part.trim().isNotEmpty) part.trim(),
        ],
        note: _note.text.trim(),
        // No compare-at total: the vendor did not state one, and inventing a
        // "was" price to print a savings badge against would be a lie.
      ),
    );
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
              _Field(
                label: 'INCLUDES (COMMA SEPARATED)',
                hint: 'Washed and folded, Standard detergent',
                controller: _inclusions,
                onChanged: _rebuild,
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
