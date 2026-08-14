import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../data/mock_data.dart';
import '../../models/saved_card.dart';
import '../../state/auth_state.dart';
import '../../state/profile_state.dart';
import '../../state/saved_cards_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/card_brand_tag.dart';
import '../../widgets/link_card_sheet.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/profile_action_tile.dart';
import '../../widgets/toggle_switch.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final savedCards = ref.watch(savedCardsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              decoration: const BoxDecoration(
                color: AppColors.slate,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Row(children: [Expanded(child: Text('Profile', style: AppText.serif(fontSize: 24, color: AppColors.cream))), _HeroIcon(icon: AppIcons.bell, onTap: () => context.push('/notifs'))]),
                  const SizedBox(height: 18),
                  const SizedBox(width: 82, height: 82, child: PlaceholderImage(label: 'You', circle: true)),
                  const SizedBox(height: 11),
                  Text('Amara Reed', style: AppText.serif(fontSize: 23, color: AppColors.cream)),
                  const SizedBox(height: 3),
                  Text('amara.reed@mail.com', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.66))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ProfileActionTile(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notification',
                          onTap: () => context.push('/notifs'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ProfileActionTile(
                          icon: Icons.local_offer_outlined,
                          label: 'Voucher',
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Your next voucher will appear here.')),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ProfileActionTile(
                          icon: Icons.history_rounded,
                          label: 'History',
                          onTap: () => context.go('/orders'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ProfileMenuRow(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile editing is coming soon.')))),
                  _ProfileMenuRow(icon: Icons.location_on_outlined, label: 'Address Management', onTap: () {}),
                  _ProfileMenuRow(icon: Icons.headset_mic_outlined, label: 'Help & Support', onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support chat is available from an active order.')))),
                  _ProfileMenuRow(icon: Icons.settings_outlined, label: 'Settings', onTap: () {}),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Text('ACCOUNT DETAILS', style: AppText.eyebrow())),
            _SectionLabel('Saved addresses'),
            Column(
              children: [
                for (var i = 0; i < profile.addresses.length; i++) ...[
                  _AddressRow(
                    label: profile.addresses[i].label,
                    line: profile.addresses[i].line,
                    onSave: (line) => notifier.updateAddressLine(i, line),
                  ),
                  if (i != profile.addresses.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
            _SectionLabel('Saved cards'),
            if (savedCards.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.creamDark),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'No cards linked yet.',
                  style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < savedCards.length; i++) ...[
                    _SavedCardRow(
                      card: savedCards[i],
                      onRemove: () => ref.read(savedCardsProvider.notifier).remove(savedCards[i].id),
                    ),
                    if (i != savedCards.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.teal, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => showLinkCardSheet(context, ref),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: Text(
                      '+ Link a card',
                      style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                    ),
                  ),
                ),
              ),
            ),
            _SectionLabel('Preferences'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < kPreferenceLabels.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: i == kPreferenceLabels.length - 1 ? Colors.transparent : AppColors.cream,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              kPreferenceLabels[i],
                              style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                          ToggleSwitch(on: profile.prefsOn[i], onTap: () => notifier.togglePref(i)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/home');
                  },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    child: Text(
                      'Log out',
                      style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.amber),
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

class _HeroIcon extends StatelessWidget {
  const _HeroIcon({required this.icon, required this.onTap});

  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: SizedBox(width: 42, height: 42, child: Center(child: AppIcon(icon, size: 18, color: AppColors.cream)))),
  );
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 1),
    decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.cream))),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(children: [Icon(icon, size: 20, color: AppColors.teal), const SizedBox(width: 13), Expanded(child: Text(label, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700))), const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted)]),
        ),
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 11),
      child: Text(text.toUpperCase(), style: AppText.eyebrow()),
    );
  }
}

class _AddressRow extends StatefulWidget {
  const _AddressRow({required this.label, required this.line, required this.onSave});

  final String label;
  final String line;
  final ValueChanged<String> onSave;

  @override
  State<_AddressRow> createState() => _AddressRowState();
}

class _AddressRowState extends State<_AddressRow> {
  bool _editing = false;
  late final _controller = TextEditingController(text: widget.line);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() => setState(() => _editing = true);

  void _cancel() {
    _controller.text = widget.line;
    setState(() => _editing = false);
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) widget.onSave(value);
    setState(() => _editing = false);
  }

  void _useCurrentLocation() {
    // Placeholder — wire up to Google Maps' location picker later.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Maps location picker coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(13)),
                alignment: Alignment.center,
                child: const AppIcon(AppIcons.locationPin, size: 15, color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      widget.line,
                      style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (!_editing)
                InkWell(
                  onTap: _startEditing,
                  child: Text('Edit', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ),
            ],
          ),
          if (_editing) ...[
            const SizedBox(height: 12),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                decoration: InputDecoration.collapsed(
                  hintText: 'Enter new address',
                  hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _useCurrentLocation,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppIcon(AppIcons.locationPin, size: 14, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Text(
                    'Use current location',
                    style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _cancel,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text('Cancel', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _save,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Text('Save', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.cream)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SavedCardRow extends StatelessWidget {
  const _SavedCardRow({required this.card, required this.onRemove});

  final SavedCard card;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.creamDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CardBrandTag(brand: card.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•••• ${card.last4}', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${card.holderName} · Expires ${card.expiry}',
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onRemove,
            child: Text('Remove', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.amber)),
          ),
        ],
      ),
    );
  }
}
