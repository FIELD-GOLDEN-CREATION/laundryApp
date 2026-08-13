import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_mock_data.dart';
import '../../state/admin_vendor_detail_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/round_back_button.dart';

class AdminVendorScreen extends ConsumerStatefulWidget {
  const AdminVendorScreen({super.key});

  @override
  ConsumerState<AdminVendorScreen> createState() => _AdminVendorScreenState();
}

class _AdminVendorScreenState extends ConsumerState<AdminVendorScreen> {
  late final _coordController = TextEditingController(text: ref.read(adminVendorDetailProvider).coordQuery);

  @override
  void dispose() {
    _coordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminVendorDetailProvider, (prev, next) {
      if (_coordController.text != next.coordQuery) _coordController.text = next.coordQuery;
    });
    final state = ref.watch(adminVendorDetailProvider);
    final notifier = ref.read(adminVendorDetailProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Align(alignment: Alignment.topLeft, child: RoundBackButton(onPressed: () => Navigator.of(context).pop())),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 70, height: 70, child: PlaceholderImage(label: 'Shop photo', borderRadius: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kVendorBiz, style: AppText.serif(fontSize: 23)),
                      const SizedBox(height: 3),
                      Text('Owner · $kVendorOwner', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(999)),
                        child: Text('Operational', style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.teal)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < kVendorFields.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: i == kVendorFields.length - 1 ? Colors.transparent : AppColors.cream)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(kVendorFields[i].key, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
                          Text(kVendorFields[i].value, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const _SectionLabel('Shop location'),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: _coordController,
                            onChanged: notifier.setCoordQuery,
                            style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700),
                            decoration: InputDecoration.collapsed(
                              hintText: 'Search coordinates or address',
                              hintStyle: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Material(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: notifier.locateMe,
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            child: Text('Locate me', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const PlaceholderImage(label: 'Google map of shop', borderRadius: 16),
                        Align(
                          alignment: const Alignment(0, -1),
                          child: Container(
                            margin: const EdgeInsets.only(top: 55),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pinned', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.muted)),
                      Text(state.coordQuery, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Material(
                    color: state.locSaved ? AppColors.tealMuted : AppColors.slate,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: notifier.saveLocation,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          state.locSaved ? '✓ Location saved' : 'Save location',
                          style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: state.locSaved ? AppColors.teal : AppColors.cream),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL PLATFORM EARNINGS', style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.62))),
                  const SizedBox(height: 5),
                  Text('TZS 107,142,360', style: AppText.serif(fontSize: 32, color: AppColors.cream)),
                  const SizedBox(height: 4),
                  Text('Since March 2025 · 1,204 orders', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.mint)),
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
