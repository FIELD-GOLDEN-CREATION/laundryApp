import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/driver_mock_data.dart';
import '../../state/driver_dash_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/account_sheet.dart';
import '../../widgets/stat_tile.dart';

class DriverDashScreen extends ConsumerWidget {
  const DriverDashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverDashProvider);
    final notifier = ref.read(driverDashProvider.notifier);
    final mins = state.secs ~/ 60;
    final secs = state.secs % 60;
    final countdown = '$mins:${secs.toString().padLeft(2, '0')}';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(online: state.online, onToggleOnline: notifier.toggleOnline, onAccount: () => showAccountSheet(context, ref)),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Row(
                children: [
                  const Expanded(child: StatTile(value: 'TZS 193,700', label: 'Earned today', bg: Colors.white, fg: AppColors.teal)),
                  const SizedBox(width: 10),
                  const Expanded(child: _CompletedTile()),
                  const SizedBox(width: 10),
                  const Expanded(child: StatTile(value: '94%', label: 'Acceptance', bg: AppColors.tealMuted, fg: AppColors.success)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.slate, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('NEXT TASK · PICKUP', style: AppText.eyebrow(color: AppColors.mint)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            '$countdown left',
                            style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.cream),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('#LD-2492 · Nina Alvarez', style: AppText.serif(fontSize: 22, color: AppColors.cream)),
                    const SizedBox(height: 4),
                    Text(
                      'Apt 4B, 88 Toure Drive, Oyster Bay → Marina Fresh Laundry · 0.8 km',
                      style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.72), height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {},
                              child: Container(
                                height: 48,
                                alignment: Alignment.center,
                                child: Text('Quick route', style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.28), width: 1.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.go('/driver/queue'),
                              child: Container(
                                height: 48,
                                alignment: Alignment.center,
                                child: Text('Open job', style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.cream)),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 11),
              child: Text('SHIFT SO FAR', style: AppText.eyebrow()),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 26),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < kDriverShiftRows.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: i == kDriverShiftRows.length - 1 ? Colors.transparent : AppColors.cream)),
                      ),
                      child: Row(
                        children: [
                          Container(width: 9, height: 9, decoration: BoxDecoration(color: kDriverShiftRows[i].dot, shape: BoxShape.circle)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${kDriverShiftRows[i].id} · ${kDriverShiftRows[i].who}',
                                  style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  kDriverShiftRows[i].meta,
                                  style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            kDriverShiftRows[i].amount,
                            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: kDriverShiftRows[i].dot),
                          ),
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

class _Header extends StatelessWidget {
  const _Header({required this.online, required this.onToggleOnline, required this.onAccount});

  final bool online;
  final VoidCallback onToggleOnline;
  final VoidCallback onAccount;

  @override
  Widget build(BuildContext context) {
    final bg = online ? AppColors.mint.withValues(alpha: 0.16) : AppColors.rust.withValues(alpha: 0.18);
    final border = online ? AppColors.mint.withValues(alpha: 0.4) : AppColors.rust.withValues(alpha: 0.42);
    final dotColor = online ? AppColors.mint : const Color(0xFFE8917C);
    final track = online ? AppColors.success : AppColors.rust;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      child: Container(
        color: AppColors.teal,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -70,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WEDNESDAY, 12 AUG · SHIFT 07:00–19:00', style: AppText.eyebrow(color: AppColors.cream.withValues(alpha: 0.6))),
                        const SizedBox(height: 6),
                        Text('Kofi Asante', style: AppText.serif(fontSize: 25, color: AppColors.cream)),
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
                          child: Center(child: Text('D', style: AppText.serif(fontSize: 17, color: AppColors.cream))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(22)),
                  child: Row(
                    children: [
                      _PulsingDot(color: dotColor),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              online ? 'You are online' : 'You are offline',
                              style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cream),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              online ? 'Receiving jobs in Ilala' : 'No new jobs will be sent to you',
                              style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.cream.withValues(alpha: 0.66)),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: onToggleOnline,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 62,
                          height: 34,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(999)),
                          alignment: online ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                          ),
                        ),
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

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Opacity(
                opacity: 1 - t,
                child: Transform.scale(
                  scale: 1 + t * 1.6,
                  child: Container(width: 12, height: 12, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
                ),
              );
            },
          ),
          Container(width: 12, height: 12, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}

class _CompletedTile extends StatelessWidget {
  const _CompletedTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '9', style: AppText.serif(fontSize: 24, color: AppColors.teal)),
                TextSpan(text: '/12', style: AppText.serif(fontSize: 15, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text('Completed', style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted)),
        ],
      ),
    );
  }
}
