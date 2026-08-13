import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_data.dart';
import '../../state/schedule_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_cta_bar.dart';
import '../../widgets/radio_option_card.dart';
import '../../widgets/round_back_button.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RoundBackButton(onPressed: () => context.pop()),
                  const SizedBox(width: 12),
                  Text('Schedule pickup', style: AppText.serif(fontSize: 24)),
                ],
              ),
              _SectionLabel('Pickup address'),
              Column(
                children: [
                  for (var i = 0; i < kAddresses.length; i++) ...[
                    RadioOptionCard(
                      label: kAddresses[i].label,
                      sub: kAddresses[i].line,
                      selected: schedule.addrIndex == i,
                      onTap: () => notifier.pickAddress(i),
                    ),
                    if (i != kAddresses.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
              _SectionLabel('Pickup day'),
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kDays.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 9),
                  itemBuilder: (_, i) {
                    final active = schedule.dayIndex == i;
                    return _DayChip(
                      dow: kDays[i].dow,
                      num: kDays[i].num,
                      active: active,
                      onTap: () => notifier.pickDay(i),
                    );
                  },
                ),
              ),
              _SectionLabel('Time window'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.7,
                children: [
                  for (var i = 0; i < kTimeSlots.length; i++)
                    _TimeSlotChip(
                      label: kTimeSlots[i],
                      active: schedule.slotIndex == i,
                      onTap: () => notifier.pickSlot(i),
                    ),
                ],
              ),
              _SectionLabel('Note for the driver'),
              TextField(
                onChanged: notifier.setNote,
                maxLines: 3,
                style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'e.g. Ring the bell twice, bags are by the door',
                  hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.creamDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.creamDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.teal),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PrimaryCtaBar(
        label: 'Continue to checkout',
        onPressed: () => context.push('/checkout'),
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

class _DayChip extends StatelessWidget {
  const _DayChip({required this.dow, required this.num, required this.active, required this.onTap});

  final String dow;
  final String num;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.teal : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: active ? AppColors.teal : AppColors.creamDark, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Column(
              children: [
                Text(
                  dow,
                  style: AppText.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: (active ? AppColors.cream : AppColors.slate).withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  num,
                  style: AppText.sans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: active ? AppColors.cream : AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.tealMuted : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: active ? AppColors.teal : AppColors.creamDark, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: AppText.sans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.teal : AppColors.slate,
            ),
          ),
        ),
      ),
    );
  }
}
