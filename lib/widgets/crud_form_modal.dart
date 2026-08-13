import 'package:flutter/material.dart';

import '../models/form_field_spec.dart';
import '../models/modal_copy.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

const _kAddRoles = ['Client', 'Vendor', 'Driver'];

/// The generic CRUD form modal reused by every admin action (ports the
/// source's `modalOpen`/`modalCopy()`). Confirm and Cancel both just close
/// the sheet — this is a prototype with no backend to actually write to,
/// same as the source.
void showCrudFormModal(BuildContext context, ModalKind kind) {
  final copy = kModalCopy[kind]!;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      var addRole = 0;
      return StatefulBuilder(
        builder: (sheetContext, setState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
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
                  Text(copy.title, style: AppText.serif(fontSize: 22)),
                  const SizedBox(height: 3),
                  Text(copy.sub, style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                  if (kind == ModalKind.add) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (var i = 0; i < _kAddRoles.length; i++) ...[
                          if (i != 0) const SizedBox(width: 7),
                          Expanded(
                            child: _RolePill(
                              label: _kAddRoles[i],
                              selected: addRole == i,
                              onTap: () => setState(() => addRole = i),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  for (var i = 0; i < copy.fields.length; i++) ...[
                    if (i != 0) const SizedBox(height: 12),
                    _ModalField(spec: copy.fields[i]),
                  ],
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
                            onTap: () => Navigator.of(sheetContext).pop(),
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
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.of(sheetContext).pop(),
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              child: Text(
                                copy.primary,
                                style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream),
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
          );
        },
      );
    },
  );
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.teal : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.teal : AppColors.creamDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: selected ? AppColors.cream : AppColors.muted),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalField extends StatelessWidget {
  const _ModalField({required this.spec});

  final FormFieldSpec spec;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(spec.label, style: AppText.eyebrow()),
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
            obscureText: spec.obscure,
            style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
            decoration: InputDecoration.collapsed(
              hintText: spec.placeholder,
              hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
        ),
      ],
    );
  }
}
