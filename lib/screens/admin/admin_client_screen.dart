import 'package:flutter/material.dart';

import '../../data/admin_mock_data.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/stat_tile.dart';

class AdminClientScreen extends StatelessWidget {
  const AdminClientScreen({super.key});

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
                const SizedBox(width: 70, height: 70, child: PlaceholderImage(label: 'Client photo', borderRadius: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kClientName, style: AppText.serif(fontSize: 24)),
                      const SizedBox(height: 3),
                      Text(kClientEmail, style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(999)),
                        child: Text('Client · active', style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.teal)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: StatTile(value: '24', label: 'Lifetime orders', bg: Colors.white, fg: AppColors.teal)),
                SizedBox(width: 10),
                Expanded(child: StatTile(value: 'TZS 2,034,240', label: 'Total spent', bg: Colors.white, fg: AppColors.teal)),
              ],
            ),
            const _SectionLabel('Live location'),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _KVRow(label: 'Coordinates', value: '6.7924° S, 39.2083° E'),
                  const SizedBox(height: 9),
                  _KVRow(label: 'Nearest address', value: '12 Chole Road, Masaki'),
                  const SizedBox(height: 12),
                  const SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: PlaceholderImage(label: 'Client location map', borderRadius: 16),
                  ),
                ],
              ),
            ),
            const _SectionLabel('Order history'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < kClientHistory.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: i == kClientHistory.length - 1 ? Colors.transparent : AppColors.cream)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              kClientHistory[i].key,
                              style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(kClientHistory[i].value, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
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

class _KVRow extends StatelessWidget {
  const _KVRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
        Text(value, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
