import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/vendor_mock_data.dart';
import '../../models/track_step_def.dart';
import '../../state/vendor_order_detail_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/barcode_strip.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/selectable_chip.dart';

class VendorOrderDetailScreen extends ConsumerWidget {
  const VendorOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorOrderDetailProvider);
    final notifier = ref.read(vendorOrderDetailProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Row(
              children: [
                RoundBackButton(onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #LD-2481', style: AppText.serif(fontSize: 23)),
                    const SizedBox(height: 2),
                    Text(
                      'Amara Reed · 8 items',
                      style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
            const _SectionLabel('Digital garment tag'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            state.tagId,
                            style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: AppColors.tealMuted,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: notifier.regenTag,
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            child: Text(
                              'New tag',
                              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const BarcodeStrip(),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < kGarmentLabels.length; i++)
                        SelectableChip(
                          label: kGarmentLabels[i],
                          selected: state.garment == i,
                          onTap: () => notifier.pickGarment(i),
                          fontSize: 11.5,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const _SectionLabel('Fabric damage inspection'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < kDamageLabels.length; i++)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => notifier.toggleDamage(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cream))),
                          child: Row(
                            children: [
                              _DamageCheckbox(checked: state.damage[i]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  kDamageLabels[i],
                                  style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      onChanged: notifier.setDamageNote,
                      maxLines: 3,
                      style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.cream,
                        hintText: 'Inspection notes for the customer…',
                        hintStyle: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _SectionLabel('Pre-existing stains'),
            Row(
              children: [
                const Expanded(child: AspectRatio(aspectRatio: 1, child: PlaceholderImage(label: 'Photo 1', borderRadius: 16))),
                const SizedBox(width: 10),
                const Expanded(child: AspectRatio(aspectRatio: 1, child: PlaceholderImage(label: 'Photo 2', borderRadius: 16))),
                const SizedBox(width: 10),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFCBD5CF), width: 1.5),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {},
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.upload_outlined, size: 22, color: AppColors.muted),
                            const SizedBox(height: 6),
                            Text('Upload', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const _SectionLabel('Processing status'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < kProcessingSteps.length; i++)
                    _ProcessStepRow(
                      step: kProcessingSteps[i],
                      done: i <= state.step,
                      onTap: () => notifier.pickStep(i),
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

class _DamageCheckbox extends StatelessWidget {
  const _DamageCheckbox({required this.checked});
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

class _ProcessStepRow extends StatelessWidget {
  const _ProcessStepRow({required this.step, required this.done, required this.onTap});

  final TrackStepDef step;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.teal : Colors.white,
                  border: Border.all(color: done ? AppColors.teal : const Color(0xFFD7D2C6), width: 2),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.cream : const Color(0xFFD7D2C6)),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  step.title,
                  style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: done ? AppColors.slate : AppColors.muted),
                ),
              ),
              Text(
                done ? step.time : 'Pending',
                style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
