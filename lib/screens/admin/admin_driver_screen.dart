import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_mock_data.dart';
import '../../state/admin_driver_detail_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/selectable_chip.dart';
import '../../widgets/stat_tile.dart';

class AdminDriverScreen extends ConsumerWidget {
  const AdminDriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transport = ref.watch(adminDriverDetailProvider);
    final notifier = ref.read(adminDriverDetailProvider.notifier);

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
                const SizedBox(width: 70, height: 70, child: PlaceholderImage(label: 'Driver photo', borderRadius: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kDriverName, style: AppText.serif(fontSize: 24)),
                      const SizedBox(height: 3),
                      Text('On duty · Kinondoni', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(999)),
                        child: Text('Delivering #LD-2481', style: AppText.sans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.amber)),
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
                  for (var i = 0; i < kDriverFields.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: i == kDriverFields.length - 1 ? Colors.transparent : AppColors.cream)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(kDriverFields[i].key, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
                          Text(kDriverFields[i].value, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const _SectionLabel('Transport type'),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.4,
              children: [
                for (var i = 0; i < kTransportLabels.length; i++)
                  SelectableChip(
                    label: kTransportLabels[i],
                    selected: transport == i,
                    onTap: () => notifier.pickTransport(i),
                    borderRadius: 14,
                    fontSize: 11,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: StatTile(value: '318', label: 'Deliveries completed', bg: Colors.white, fg: AppColors.teal)),
                SizedBox(width: 10),
                Expanded(child: StatTile(value: 'TZS 381,680', label: 'Wallet balance', bg: AppColors.amberLight, fg: AppColors.amber)),
              ],
            ),
            const _SectionLabel('Active route'),
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const PlaceholderImage(label: 'Active route map', borderRadius: 20),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.16), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Text(
                        '2.4 km left · ETA 11 min',
                        style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                      ),
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
