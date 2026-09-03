import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/icons/app_icons.dart';
import '../../../models/saved_card.dart';
import '../../../state/auth_state.dart';
import '../../../state/profile_state.dart';
import '../../../state/saved_cards_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/card_brand_tag.dart';
import '../../../widgets/link_card_sheet.dart';
import '../../../widgets/profile_action_tile.dart';
import '../../../widgets/remote_image.dart';
import '../../../widgets/toggle_switch.dart';

/// Notification preference rows — display configuration.
const _kPreferenceLabels = ['Push notifications', 'Eco detergent by default', 'Contactless pickup'];

enum _ImagePickSource { camera, gallery }

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  /// Bottom sheet offering Camera / Gallery.
  Future<_ImagePickSource?> _chooseImageSource() {
    final language = ref.read(clientPreferencesProvider).language;
    return showModalBottomSheet<_ImagePickSource>(
      context: context,
      backgroundColor: AppColors.cream,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.teal),
              title: Text(clientLabel('Take photo', 'Piga picha', language), style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(sheetContext, _ImagePickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.teal),
              title: Text(clientLabel('Choose from gallery', 'Chagua kwenye picha zako', language), style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(sheetContext, _ImagePickSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  /// Runs the OS image picker for [source], surfacing a permission/access
  /// failure (denied camera/gallery access, no camera present, etc.) as a
  /// snackbar instead of letting it vanish as an uncaught exception.
  Future<XFile?> _pickFile(_ImagePickSource source) async {
    final language = ref.read(clientPreferencesProvider).language;
    try {
      final xfile = await _imagePicker.pickImage(
        source: source == _ImagePickSource.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      return xfile;
    } catch (_) {
      if (!mounted) return null;
      final isCamera = source == _ImagePickSource.camera;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(clientLabel(
            'Could not access the ${isCamera ? 'camera' : 'gallery'}. Check app permissions in your phone settings.',
            'Imeshindwa kufikia ${isCamera ? 'kamera' : 'picha zako'}. Angalia ruhusa za programu kwenye mipangilio ya simu.',
            language,
          )),
        ),
      );
      return null;
    }
  }

  Future<void> _editProfilePhoto() async {
    final source = await _chooseImageSource();
    if (source == null || !mounted) return;
    final file = await _pickFile(source);
    if (file == null || !mounted) return;
    final language = ref.read(clientPreferencesProvider).language;
    final ok = await ref.read(profileProvider.notifier).uploadProfilePhoto(file);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(clientLabel('Could not upload photo. Please try again.', 'Imeshindwa kupakia picha. Jaribu tena.', language))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final savedCards = ref.watch(savedCardsProvider);
    final clientPrefs = ref.watch(clientPreferencesProvider);
    final language = clientPrefs.language;
    final authEmail = ref.watch(authProvider.select((s) => s.authEmail));

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
               child: Stack(
                 children: [
                   Positioned.fill(
                     child: Opacity(
                       opacity: 0.13,
                       child: RemoteImage(url: profile.photoUrl ?? '', fallback: profile.photoLabel, fit: BoxFit.cover),
                     ),
                   ),
                   Positioned.fill(child: Container(color: AppColors.slate.withValues(alpha: 0.84))),
                   Column(
                     children: [
                   Row(children: [Expanded(child: Text(clientLabel('Profile', 'Wasifu', language), style: AppText.serif(fontSize: 24, color: AppColors.cream))), _HeroIcon(icon: AppIcons.bell, onTap: () => context.push('/notifs'))]),
                  const SizedBox(height: 18),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      SizedBox(
                        width: 82,
                        height: 82,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RemoteImage(url: profile.photoUrl ?? '', fallback: profile.photoLabel, circle: true, borderRadius: 41),
                            if (profile.uploadingProfilePhoto)
                              const DecoratedBox(
                                decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream)),
                              ),
                          ],
                        ),
                      ),
                      FloatingActionButton.small(
                        backgroundColor: AppColors.teal,
                        onPressed: profile.uploadingProfilePhoto ? null : _editProfilePhoto,
                        child: const Icon(Icons.camera_alt_outlined, color: AppColors.cream),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                   Text(profile.name, style: AppText.serif(fontSize: 23, color: AppColors.cream)),
                  const SizedBox(height: 3),
                   Text(authEmail.isNotEmpty ? authEmail : profile.phone, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.66))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ProfileActionTile(
                          icon: Icons.notifications_none_rounded,
                           label: clientLabel('Notification', 'Arifa', language),
                          onTap: () => context.push('/notifs'),
                        ),
                      ),
                      const SizedBox(width: 8),
                       Expanded(
                        child: ProfileActionTile(
                          icon: Icons.history_rounded,
                           label: clientLabel('History', 'Historia', language),
                          onTap: () => context.go('/orders'),
                        ),
                      ),
                     ],
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
                   _ProfileMenuRow(icon: Icons.person_outline_rounded, label: clientLabel('Edit Profile', 'Hariri wasifu', language), onTap: () => context.push('/profile/edit')),
                  _ProfileMenuRow(icon: Icons.headset_mic_outlined, label: clientLabel('Help & Support', 'Msaada', language), onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(clientLabel('Support chat is available from an active order.', 'Mazungumzo ya msaada yanapatikana kwenye oda inayoendelea.', language))))),
                   _ProfileMenuRow(icon: Icons.settings_outlined, label: clientLabel('Settings', 'Mipangilio', language), onTap: () => context.push('/profile/settings')),
                ],
              ),
            ),
            // Become a Vendor CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: AppColors.tealMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: AppColors.teal.withValues(alpha: 0.2), width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push('/profile/apply-vendor'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.teal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.store_rounded, size: 20, color: AppColors.cream),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientLabel('Become a Vendor', 'Kuwa Muuzaji', language),
                                style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                clientLabel('Start your laundry business on FreshFold', 'Anza biashara yako ya ufagaji kwenye FreshFold', language),
                                style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.teal),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Text(clientLabel('ACCOUNT DETAILS', 'TAARIFA ZA AKAUNTI', language), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context)))),
            _SectionLabel(clientLabel('Saved addresses', 'Anwani zilizohifadhiwa', language)),
            if (profile.addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                   color: AppColors.clientSurface(context),
                   border: Border.all(color: AppColors.clientBorder(context)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                   clientLabel('No addresses saved yet.', 'Hakuna anwani iliyohifadhiwa.', language),
                   style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                ),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < profile.addresses.length; i++) ...[
                    _AddressRow(
                      key: ValueKey(profile.addresses[i].id ?? 'addr-$i'),
                      label: profile.addresses[i].label,
                      line: profile.addresses[i].line,
                      onSave: (line) => notifier.updateAddressLine(i, line),
                      onDelete: () => notifier.removeAddressAt(i),
                    ),
                    if (i != profile.addresses.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.teal, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showAddAddressSheet(context, ref),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    child: Text(
                      '+ ${clientLabel('Add address', 'Ongeza anwani', language)}',
                      style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                    ),
                  ),
                ),
              ),
            ),
            _SectionLabel(clientLabel('Saved cards', 'Kadi zilizohifadhiwa', language)),
            if (savedCards.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                   color: AppColors.clientSurface(context),
                   border: Border.all(color: AppColors.clientBorder(context)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                   clientLabel('No cards linked yet.', 'Hakuna kadi iliyounganishwa.', language),
                   style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                ),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < savedCards.length; i++) ...[
                    _SavedCardRow(
                      card: savedCards[i],
                      onRemove: () => ref.read(savedCardsProvider.notifier).removeCard(savedCards[i].id),
                    ),
                    if (i != savedCards.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    child: Text(
                      '+ Link a card',
                      style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                    ),
                  ),
                ),
              ),
            ),
             _SectionLabel(clientLabel('Preferences', 'Mapendeleo', language)),
            Container(
              decoration: BoxDecoration(
                 color: AppColors.clientSurface(context),
                 border: Border.all(color: AppColors.clientBorder(context)),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < _kPreferenceLabels.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                             color: i == _kPreferenceLabels.length - 1 ? Colors.transparent : AppColors.clientBorder(context),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                               clientLabel(_kPreferenceLabels[i], ['Arifa za oda', 'Ofa na matangazo', 'Vidokezo vya utunzaji'][i], language),
                               style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.clientText(context)),
                            ),
                          ),
                          ToggleSwitch(on: clientPrefs.prefsOn[i], onTap: () => ref.read(clientPreferencesProvider.notifier).togglePref(i)),
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
                       clientLabel('Log out', 'Toka', language),
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
     decoration: BoxDecoration(color: AppColors.clientSurface(context), border: Border(bottom: BorderSide(color: AppColors.clientBorder(context)))),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
           child: Row(children: [Icon(icon, size: 20, color: AppColors.teal), const SizedBox(width: 13), Expanded(child: Text(label, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.clientText(context)))), Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.clientSecondaryText(context))]),
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
       child: Text(text.toUpperCase(), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))),
    );
  }
}

class _AddressRow extends StatefulWidget {
  const _AddressRow({super.key, required this.label, required this.line, required this.onSave, required this.onDelete});

  final String label;
  final String line;
  final ValueChanged<String> onSave;
  final Future<bool> Function() onDelete;

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

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete address?', style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text(
          'This will remove "${widget.label}" from your saved addresses. This cannot be undone.',
          style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final ok = await widget.onDelete();
              if (!mounted || ok) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not delete address. Please try again.')),
              );
            },
            child: Text('Delete', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
         color: AppColors.clientSurface(context),
         border: Border.all(color: AppColors.clientBorder(context)),
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
                     Text(widget.label, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                    const SizedBox(height: 2),
                    Text(
                      widget.line,
                       style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                    ),
                  ],
                ),
              ),
              if (!_editing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _confirmDelete,
                      child: Text('Delete', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.danger)),
                    ),
                    const SizedBox(width: 14),
                    InkWell(
                      onTap: _startEditing,
                      child: Text('Edit', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                    ),
                  ],
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

/// The "add address" bottom-sheet form for Profile's "Saved addresses"
/// section — mirrors the shape of `showLinkCardSheet`.
void _showAddAddressSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _AddAddressSheet(ref: ref),
  );
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _labelCtrl = TextEditingController();
  final _lineCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _labelCtrl.text.trim();
    final line = _lineCtrl.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Enter a label, e.g. Home or Work.');
      return;
    }
    if (line.isEmpty) {
      setState(() => _error = 'Enter the address.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await widget.ref.read(profileProvider.notifier).addAddress(label, line);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = 'Could not save address. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                Text('Add address', style: AppText.serif(fontSize: 22)),
                const SizedBox(height: 3),
                Text(
                  'Saved to your account for pickup and delivery',
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                _AddAddressField(label: 'Label', hint: 'Home, Work, ...', controller: _labelCtrl),
                const SizedBox(height: 12),
                _AddAddressField(label: 'Address', hint: 'Street, area, city', controller: _lineCtrl),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _saving ? null : () => Navigator.of(context).pop(),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: Text('Cancel', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 7,
                      child: Material(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _saving ? null : _save,
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream),
                                  )
                                : Text('Save address', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream)),
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
      ),
    );
  }
}

class _AddAddressField extends StatelessWidget {
  const _AddAddressField({required this.label, required this.hint, required this.controller});

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.eyebrow()),
        const SizedBox(height: 7),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.creamDark),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
        ),
      ],
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
                 color: AppColors.clientSurface(context),
                 border: Border.all(color: AppColors.clientBorder(context)),
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
                Text('â€¢â€¢â€¢â€¢ ${card.last4}', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${card.holderName} Â· Expires ${card.expiry}',
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
