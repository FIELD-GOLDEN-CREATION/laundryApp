import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/driver_mock_data.dart';
import '../../models/modal_copy.dart';
import '../../state/driver_profile_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/crud_form_modal.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/toggle_switch.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverProfileProvider);
    final notifier = ref.read(driverProfileProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Driver profile', style: AppText.serif(fontSize: 27)),
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 64, height: 64, child: PlaceholderImage(label: 'Driver photo', borderRadius: 20)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kofi Asante', style: AppText.serif(fontSize: 21)),
                            const SizedBox(height: 2),
                            Text(
                              'driver@gmail.com',
                              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                            ),
                            const SizedBox(height: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(999)),
                              child: Text(
                                '✓ Verified · Admin locked',
                                style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _ReadOnlyField(label: 'Vehicle type', value: 'Motorcycle')),
                      const SizedBox(width: 11),
                      Expanded(child: _ReadOnlyField(label: 'Plate number', value: 'MC 109 RTX')),
                    ],
                  ),
                  const SizedBox(height: 11),
                  const _ReadOnlyField(label: 'NIDA registration', value: '1998-0417-22841-19'),
                  const SizedBox(height: 12),
                  Text(
                    'Vehicle and identity fields are read-only. Contact an administrator to change them.',
                    style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted, height: 1.5),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 11),
              child: Text('HOME BASE', style: AppText.eyebrow()),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 130, width: double.infinity, child: PlaceholderImage(label: 'Home base map')),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('27 Kariakoo Street, Ilala', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(
                          'Registered 04 Mar 2026 · jobs routed from here',
                          style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Material(
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.creamDark),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: notifier.requestLoc,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                child: Text(
                                  state.locReqDone ? '✓ Update requested' : 'Request location update',
                                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal),
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 24, 0, 11),
              child: Text('APP CONTROLS', style: AppText.eyebrow()),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < kDriverAppControls.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: i == kDriverAppControls.length - 1 ? Colors.transparent : AppColors.cream)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(kDriverAppControls[i].$1, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(
                                  kDriverAppControls[i].$2,
                                  style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          ToggleSwitch(on: state.togglesOn[i], onTap: () => notifier.toggleAppControl(i)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => showCrudFormModal(context, ModalKind.changePassword),
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      child: Text('Change password', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.eyebrow()),
          const SizedBox(height: 4),
          Text(value, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
