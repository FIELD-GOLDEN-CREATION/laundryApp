import 'package:flutter/material.dart';

import '../../data/admin_mock_data.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/round_back_button.dart';

class AdminStaffScreen extends StatelessWidget {
  const AdminStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(width: 70, height: 70, child: PlaceholderImage(label: 'Staff photo', borderRadius: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kStaffName, style: AppText.serif(fontSize: 24)),
                      const SizedBox(height: 3),
                      Text(kStaffRole, style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(999)),
                        child: Text('Staff · active', style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.teal)),
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
                  for (var i = 0; i < kStaffFields.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: i == kStaffFields.length - 1 ? Colors.transparent : AppColors.cream)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(kStaffFields[i].key, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
                          Text(kStaffFields[i].value, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const _SectionLabel('Permissions'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final permission in kStaffPermissions)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(999)),
                    child: Text(permission, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.teal)),
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
