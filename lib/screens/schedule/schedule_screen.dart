import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../data/mock_data.dart';
import '../../state/schedule_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/location.dart';
import '../../widgets/map_grid_painter.dart';
import '../../widgets/primary_cta_bar.dart';
import '../../widgets/radio_option_card.dart';
import '../../widgets/round_back_button.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _locating = false;

  Future<void> _locateMe() async {
    if (_locating) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    try {
      final point = await locateUser();
      ref.read(scheduleProvider.notifier).setCurrentLocation(point.label);
    } on LocationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not get your location.')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);

    final mapLabel = schedule.isCurrentLocation
        ? schedule.currentLocation
        : kAddresses[schedule.addrIndex].line;

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
              const SizedBox(height: 18),
              _MapPreview(label: mapLabel, locating: _locating),
              _SectionLabel('Pickup address'),
              Column(
                children: [
                  for (var i = 0; i < kAddresses.length; i++) ...[
                    RadioOptionCard(
                      label: kAddresses[i].label,
                      sub: kAddresses[i].line,
                      selected: schedule.addrIndex == i,
                      leading: _AddressIcon(icon: i == 0 ? AppIcons.home : AppIcons.office),
                      onTap: () => notifier.pickAddress(i),
                    ),
                    if (i != kAddresses.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 10),
                  RadioOptionCard(
                    label: 'Locate me',
                    sub: schedule.isCurrentLocation ? schedule.currentLocation : 'Use my current location (GPS)',
                    selected: schedule.isCurrentLocation,
                    leading: _AddressIcon(icon: AppIcons.locate, bg: AppColors.amberLight, fg: AppColors.amber),
                    onTap: () => _locateMe(),
                  ),
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

/// A stylised map preview of the pickup area — a fixed-height, properly
/// sized tile with a location pin and the selected address, so the location
/// reads visually instead of as a bare list row.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.label, required this.locating});

  final String label;
  final bool locating;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.tealMuted),
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
            Center(
              child: locating
                  ? const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.teal))
                  : const _MapPin(),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  locating ? 'Finding your location…' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const AppIcon(AppIcons.locationPin, size: 20, color: AppColors.cream),
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

class _AddressIcon extends StatelessWidget {
  const _AddressIcon({required this.icon, this.bg = AppColors.tealMuted, this.fg = AppColors.teal});

  final String icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
      alignment: Alignment.center,
      child: AppIcon(icon, size: 19, color: fg),
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
