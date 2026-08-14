import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_mock_data.dart';
import '../../models/map_pin.dart';
import '../../state/admin_dash_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/account_sheet.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/bar_chart_row.dart';
import '../../widgets/map_grid_painter.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapSeed = ref.watch(adminDashProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onAccount: () => showAccountSheet(context, ref)),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('LIVE OPERATIONS', style: AppText.eyebrow()),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        '$kLiveDrivers drivers moving',
                        style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.teal),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  height: 210,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.tealMuted,
                    border: Border.all(color: AppColors.creamDark),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(painter: MapGridPainter()),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppColors.teal.withValues(alpha: 0.08)],
                          ),
                        ),
                      ),
                      for (final pin in kDriverMapPins)
                        Positioned(
                          left: 0,
                          top: 0,
                          right: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment(pin.left * 2 - 1 + (mapSeed * 0.02), pin.top * 2 - 1),
                            child: _MapPinWidget(pin: pin),
                          ),
                        ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => ref.read(adminDashProvider.notifier).shuffleMap(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(12)),
                              child: Text(
                                'Refresh GPS',
                                style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.teal),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _SectionLabel('Urgent alerts'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    for (var i = 0; i < kAdminAlerts.length; i++) ...[
                      AlertCard(
                        title: kAdminAlerts[i].title,
                        sub: kAdminAlerts[i].sub,
                        tag: kAdminAlerts[i].tag,
                        accentColor: kAdminAlerts[i].accentColor,
                        tagBg: kAdminAlerts[i].tagBg,
                        onTap: () => context.push('/admin/vendor'),
                      ),
                      if (i != kAdminAlerts.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              const _SectionLabel('Daily velocity'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.creamDark),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Orders per hour', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                        Text('Peak 6 – 8 PM', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.amber)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    BarChartRow(
                      height: 96,
                      gap: 5,
                      barRadius: 5,
                      bars: [
                        for (var i = 0; i < kVelocityBarFractions.length; i++)
                          BarDatum(
                            heightFraction: kVelocityBarFractions[i],
                            color: i == 6 ? AppColors.amber : AppColors.tealMuted,
                            label: kVelocityBarLabels[i],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAccount});
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        color: AppColors.teal,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('COMMAND CENTER · 12 AUG', style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.6))),
                        const SizedBox(height: 6),
                        Text('Platform overview', style: AppText.serif(fontSize: 25, color: AppColors.cream)),
                      ],
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onAccount,
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Center(child: Text('A', style: AppText.serif(fontSize: 17, color: AppColors.cream))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.3,
                  children: [
                    for (final card in kSysCards)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              card.label.toUpperCase(),
                              style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.62)),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(card.value, style: AppText.serif(fontSize: 26, color: AppColors.cream)),
                                const SizedBox(width: 7),
                                Text(card.delta, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: card.deltaFg)),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
      ),
    );
  }
}

class _MapPinWidget extends StatelessWidget {
  const _MapPinWidget({required this.pin});
  final MapPin pin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: pin.bg,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: Text(pin.initial, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.16), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Text(
            pin.label,
            style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 11),
      child: Text(text.toUpperCase(), style: AppText.eyebrow()),
    );
  }
}
