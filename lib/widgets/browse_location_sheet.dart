import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/icons/app_icons.dart';
import '../models/address.dart';
import '../state/browse_location_state.dart';
import '../state/profile_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'radio_option_card.dart';

/// Asks the customer whether shop distances should be measured from a saved
/// profile address or their live GPS location — same two-way choice
/// `schedule_screen.dart` offers for delivery pickup, reused here for
/// "how far is this vendor" on Search's shop cards.
Future<void> showBrowseLocationSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _BrowseLocationSheet(),
  );
}

class _BrowseLocationSheet extends ConsumerWidget {
  const _BrowseLocationSheet();

  Future<void> _pickSavedAddress(BuildContext context, WidgetRef ref, Address address) async {
    ref.read(browseLocationProvider.notifier).useSavedAddress(address);
    Navigator.of(context).pop();
  }

  Future<void> _pickCurrentLocation(BuildContext context, WidgetRef ref) async {
    await ref.read(browseLocationProvider.notifier).useCurrentLocation();
    if (!context.mounted) return;
    final error = ref.read(browseLocationProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(browseLocationProvider);
    final addresses = ref.watch(profileProvider.select((s) => s.addresses));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFFDED8CA), borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Text('Where should we measure from?', style: AppText.serif(fontSize: 21)),
              const SizedBox(height: 4),
              Text(
                'Pick a location so we can show how far each vendor is from you.',
                style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < addresses.length; i++) ...[
                RadioOptionCard(
                  label: addresses[i].label,
                  sub: addresses[i].line,
                  selected: loc.source == BrowseLocationSource.savedAddress && loc.savedAddressId == addresses[i].id,
                  leading: _LocationIcon(icon: i == 0 ? AppIcons.home : AppIcons.office),
                  onTap: () => _pickSavedAddress(context, ref, addresses[i]),
                ),
                const SizedBox(height: 10),
              ],
              RadioOptionCard(
                label: 'Use my current location',
                sub: loc.isLocating
                    ? 'Locating…'
                    : loc.source == BrowseLocationSource.gps
                        ? loc.label
                        : loc.prefetchedLabel ?? 'Use GPS to find nearby vendors',
                selected: loc.source == BrowseLocationSource.gps,
                leading: loc.isLocating
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.all(11),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.amber),
                        ),
                      )
                    : _LocationIcon(icon: AppIcons.locate, bg: AppColors.amberLight, fg: AppColors.amber),
                onTap: loc.isLocating ? () {} : () => _pickCurrentLocation(context, ref),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(browseLocationProvider.notifier).markPrompted();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Skip for now',
                    style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationIcon extends StatelessWidget {
  const _LocationIcon({required this.icon, this.bg = AppColors.tealMuted, this.fg = AppColors.teal});

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
