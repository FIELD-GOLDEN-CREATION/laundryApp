import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/app_icons.dart';
import '../../data/driver_mock_data.dart';
import '../../models/driver_job.dart';
import '../../state/driver_queue_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/scan_sheet.dart';

const _kTabLabels = ['Pickups', 'Deliveries'];

const _kSteps = [
  (label: 'Accept job', bg: AppColors.teal, fg: AppColors.cream),
  (label: 'Arrived at location', bg: AppColors.amber, fg: Colors.white),
  (label: 'Verify & collect', bg: AppColors.amber, fg: Colors.white),
  (label: 'Confirm handoff', bg: AppColors.success, fg: Colors.white),
  (label: '✓ Completed', bg: AppColors.tealMuted, fg: AppColors.teal),
];

class DriverQueueScreen extends ConsumerWidget {
  const DriverQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(driverQueueProvider);
    final notifier = ref.read(driverQueueProvider.notifier);
    final jobs = state.tab == 0 ? kDriverPickupJobs : kDriverDeliveryJobs;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Task queue', style: AppText.serif(fontSize: 28)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  for (var i = 0; i < _kTabLabels.length; i++)
                    Expanded(
                      child: _SegmentTab(label: _kTabLabels[i], active: state.tab == i, onTap: () => notifier.pickTab(i)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < jobs.length; i++) ...[
              _JobCard(
                job: jobs[i],
                step: state.step[jobs[i].id] ?? 0,
                expanded: state.openId == jobs[i].id,
                onToggle: () => notifier.toggleExpand(jobs[i].id),
                onStep: () {
                  final wasVerifyStep = (state.step[jobs[i].id] ?? 0) == 2;
                  notifier.onStep(jobs[i].id);
                  if (wasVerifyStep) showScanSheet(context);
                },
              ),
              if (i != jobs.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: active ? AppColors.teal : AppColors.muted),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.step, required this.expanded, required this.onToggle, required this.onStep});

  final DriverJob job;
  final int step;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onStep;

  @override
  Widget build(BuildContext context) {
    final cur = _kSteps[step.clamp(0, 4)];
    final tag = step == 0 ? 'Offered' : (step >= 4 ? 'Completed' : 'In progress');
    final tagFg = step == 0 ? AppColors.amber : (step >= 4 ? AppColors.success : AppColors.teal);
    final tagBg = step == 0 ? AppColors.amberLight : (step >= 4 ? AppColors.successLight : AppColors.tealMuted);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${job.id} · ${job.whoLabel}',
                          style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(job.who, style: AppText.sans(fontSize: 15.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(
                          '${job.dist} · ${job.pay}',
                          style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(tag, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: tagFg)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i != 0) const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < step ? AppColors.success : (i == step ? AppColors.amber : AppColors.creamDark),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (expanded) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1, color: AppColors.cream)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: AppIcon(AppIcons.locationPin, size: 15, color: AppColors.teal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(job.addr, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, height: 1.5)),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SPECIAL HANDLING', style: AppText.eyebrow(color: AppColors.amber)),
                  const SizedBox(height: 4),
                  Text(
                    job.note,
                    style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF8A5A12), height: 1.5),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  Material(
                    color: AppColors.tealMuted,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {},
                      child: const SizedBox(width: 52, height: 50, child: Center(child: AppIcon(AppIcons.foldedMap, size: 18))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: cur.bg,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onStep,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          child: Text(cur.label, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: cur.fg)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
