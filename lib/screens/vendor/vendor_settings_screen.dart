import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/icons/app_icons.dart';
import '../../state/vendor_profile_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/location.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/remote_image.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/toggle_switch.dart';

/// Pure UI config — the opening/closing time picker options.
const _kVendorTimeOptions = [
  '6:00 AM', '7:00 AM', '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
  '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM', '7:00 PM',
  '8:00 PM', '9:00 PM', '10:00 PM', '11:00 PM',
];

enum _ImagePickSource { camera, gallery, url }

/// The vendor-facing settings hub, reached from the account sheet's
/// "Settings" button. Mirrors the layout/design language of
/// `screens/customer/profile/profile_screen.dart` (hero header + eyebrow section
/// labels + white bordered cards) but every field auto-saves to
/// [vendorProfileProvider] as it changes — there's no separate Save button,
/// so the "Last saved" caption at the bottom and the live hero title above
/// double as the trace that an edit actually took hold.
class VendorSettingsScreen extends ConsumerStatefulWidget {
  const VendorSettingsScreen({super.key});

  @override
  ConsumerState<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends ConsumerState<VendorSettingsScreen> {
  final _imagePicker = ImagePicker();
  bool _locating = false;

  void _chooseTime(String sheetTitle, String value, ValueChanged<String> onChanged) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sheetTitle, style: AppText.serif(fontSize: 22)),
              const SizedBox(height: 6),
              SizedBox(
                height: 320,
                child: ListView(
                  children: [
                    for (final option in _kVendorTimeOptions)
                      ListTile(
                        title: Text(option, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700)),
                        trailing: option == value ? const Icon(Icons.check_rounded, color: AppColors.teal) : null,
                        onTap: () {
                          onChanged(option);
                          Navigator.pop(sheetContext);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet offering Camera / Gallery / (optionally) a pasted URL.
  Future<_ImagePickSource?> _chooseImageSource({required bool allowUrl}) {
    final language = ref.read(vendorProfileProvider).language;
    return showModalBottomSheet<_ImagePickSource>(
      context: context,
      backgroundColor: AppColors.cream,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.teal),
              title: Text(vendorLabel('Take photo', 'Piga picha', language), style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(sheetContext, _ImagePickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.teal),
              title: Text(vendorLabel('Choose from gallery', 'Chagua kwenye picha zako', language), style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(sheetContext, _ImagePickSource.gallery),
            ),
            if (allowUrl)
              ListTile(
                leading: const Icon(Icons.link_rounded, color: AppColors.teal),
                title: Text(vendorLabel('Paste image URL', 'Bandika kiungo cha picha', language), style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(sheetContext, _ImagePickSource.url),
              ),
          ],
        ),
      ),
    );
  }

  Future<String?> _promptImageUrl() {
    final language = ref.read(vendorProfileProvider).language;
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text(vendorLabel('Image URL', 'Kiungo cha picha', language), style: AppText.serif(fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(hintText: 'https://example.com/photo.jpg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(vendorLabel('Cancel', 'Ghairi', language)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(vendorLabel('Add', 'Ongeza', language)),
          ),
        ],
      ),
    );
  }

  /// Runs the OS image picker for [source], surfacing a permission/access
  /// failure (denied camera/gallery access, no camera present, etc.) as a
  /// snackbar instead of letting it vanish as an uncaught exception.
  Future<File?> _pickFile(_ImagePickSource source) async {
    final language = ref.read(vendorProfileProvider).language;
    try {
      final xfile = await _imagePicker.pickImage(
        source: source == _ImagePickSource.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (xfile == null) return null;
      return File(xfile.path);
    } catch (_) {
      if (!mounted) return null;
      final isCamera = source == _ImagePickSource.camera;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vendorLabel(
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
    final source = await _chooseImageSource(allowUrl: false);
    if (source == null || !mounted) return;
    final file = await _pickFile(source);
    if (file == null || !mounted) return;
    final language = ref.read(vendorProfileProvider).language;
    final ok = await ref.read(vendorProfileProvider.notifier).uploadProfilePhoto(file);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vendorLabel('Could not upload photo. Please try again.', 'Imeshindwa kupakia picha. Jaribu tena.', language))),
    );
  }

  Future<void> _addShopPhoto() async {
    final source = await _chooseImageSource(allowUrl: true);
    if (source == null || !mounted) return;
    final notifier = ref.read(vendorProfileProvider.notifier);
    final language = ref.read(vendorProfileProvider).language;
    bool ok;
    if (source == _ImagePickSource.url) {
      final url = await _promptImageUrl();
      if (url == null || url.isEmpty || !mounted) return;
      ok = await notifier.addShopPhotoFromUrl(url);
    } else {
      final file = await _pickFile(source);
      if (file == null || !mounted) return;
      ok = await notifier.addShopPhotoFromFile(file);
    }
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vendorLabel('Could not add photo. Please try again.', 'Imeshindwa kuongeza picha. Jaribu tena.', language))),
    );
  }

  Future<void> _removeShopPhoto(int i) async {
    final language = ref.read(vendorProfileProvider).language;
    final ok = await ref.read(vendorProfileProvider.notifier).removeShopPhoto(i);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vendorLabel('Could not remove photo. Please try again.', 'Imeshindwa kuondoa picha. Jaribu tena.', language))),
    );
  }

  /// GPS fix → reverse-geocoded street address → saved as the office
  /// address, mirroring the customer app's "use my current location" flow
  /// in `schedule_screen.dart` (same [locateUserWithAddress] helper).
  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    final notifier = ref.read(vendorProfileProvider.notifier);
    final language = ref.read(vendorProfileProvider).language;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    try {
      final resolved = await locateUserWithAddress();
      notifier.setLocationFromGps(
        address: resolved.displayLabel,
        lat: resolved.point.latitude,
        lng: resolved.point.longitude,
      );
    } on LocationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(vendorLabel('Could not get your location.', 'Imeshindwa kupata mahali ulipo.', language))),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _chooseLanguage() {
    final notifier = ref.read(vendorProfileProvider.notifier);
    final current = ref.read(vendorProfileProvider).language;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final lang in kVendorLanguageOptions)
              ListTile(
                title: Text(lang, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700)),
                trailing: lang == current ? const Icon(Icons.check_rounded, color: AppColors.teal) : null,
                onTap: () {
                  notifier.updateLanguage(lang);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendor = ref.watch(vendorProfileProvider);
    final notifier = ref.read(vendorProfileProvider.notifier);
    final language = vendor.language;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            _Hero(vendor: vendor, onEditPhoto: _editProfilePhoto),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(vendorLabel('Shop details', 'Maelezo ya duka', language)),
                  _EditableInfoCard(
                    icon: const Icon(Icons.storefront_outlined, size: 17, color: AppColors.teal),
                    label: vendorLabel('Shop name', 'Jina la duka', language),
                    value: vendor.shopTitle,
                    hint: vendorLabel('Enter shop name', 'Weka jina la duka', language),
                    editLabel: vendorLabel('Edit', 'Hariri', language),
                    saveLabel: vendorLabel('Save', 'Hifadhi', language),
                    cancelLabel: vendorLabel('Cancel', 'Ghairi', language),
                    onSave: notifier.updateShopTitle,
                  ),
                  _EditableInfoCard(
                    icon: const Icon(Icons.notes_rounded, size: 17, color: AppColors.teal),
                    label: vendorLabel('Bio', 'Maelezo mafupi', language),
                    value: vendor.bio,
                    hint: vendorLabel('Tell customers about your shop', 'Waambie wateja kuhusu duka lako', language),
                    editLabel: vendorLabel('Edit', 'Hariri', language),
                    saveLabel: vendorLabel('Save', 'Hifadhi', language),
                    cancelLabel: vendorLabel('Cancel', 'Ghairi', language),
                    maxLines: 4,
                    onSave: notifier.updateBio,
                  ),

                  _SectionLabel(vendorLabel('Location', 'Mahali', language)),
                  _EditableInfoCard(
                    icon: const AppIcon(AppIcons.office, size: 16, color: AppColors.teal),
                    label: vendorLabel('Office address', 'Anwani ya ofisi', language),
                    value: vendor.officeAddress,
                    hint: vendorLabel('Enter office address', 'Weka anwani ya ofisi', language),
                    editLabel: vendorLabel('Edit', 'Hariri', language),
                    saveLabel: vendorLabel('Save', 'Hifadhi', language),
                    cancelLabel: vendorLabel('Cancel', 'Ghairi', language),
                    onSave: notifier.updateOfficeAddress,
                    footer: InkWell(
                      onTap: _locating ? null : _useCurrentLocation,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_locating)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                            )
                          else
                            const AppIcon(AppIcons.locationPin, size: 14, color: AppColors.teal),
                          const SizedBox(width: 6),
                          Text(
                            _locating
                                ? vendorLabel('Locating…', 'Inatafuta mahali…', language)
                                : vendorLabel('Use current location', 'Tumia mahali pa sasa', language),
                            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.teal),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _SectionLabel(vendorLabel('Working schedule', 'Ratiba ya kazi', language)),
                  _WeekdayPicker(days: vendor.workingDays, onToggle: notifier.toggleWorkingDay),
                  const SizedBox(height: 10),
                  _TimeRow(
                    icon: Icons.wb_sunny_outlined,
                    label: vendorLabel('Opens at', 'Inafunguliwa saa', language),
                    value: vendor.openTime,
                    onTap: () => _chooseTime(vendorLabel('Opening time', 'Muda wa kufungua', language), vendor.openTime, notifier.updateOpenTime),
                  ),
                  const SizedBox(height: 8),
                  _TimeRow(
                    icon: Icons.nights_stay_outlined,
                    label: vendorLabel('Closes at', 'Inafungwa saa', language),
                    value: vendor.closeTime,
                    onTap: () => _chooseTime(vendorLabel('Closing time', 'Muda wa kufunga', language), vendor.closeTime, notifier.updateCloseTime),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vendor.scheduleSummary,
                    style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),

                  _SectionLabel(vendorLabel('Shop status', 'Hali ya duka', language)),
                  _StatusCard(isOpen: vendor.isOpen, onToggle: notifier.toggleOpen, language: language),

                  _SectionLabel('${vendorLabel('Shop photos', 'Picha za duka', language)} (${vendor.shopPhotos.length}/6)'),
                  _ShopPhotosStrip(
                    photos: vendor.shopPhotos,
                    uploading: vendor.uploadingShopPhoto,
                    onAdd: _addShopPhoto,
                    onRemove: _removeShopPhoto,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vendorLabel(
                      'Shown to customers as a slideshow on your shop page, 4s per photo.',
                      'Zinaonyeshwa kwa wateja kama slaidi kwenye ukurasa wa duka lako, sekunde 4 kwa kila picha.',
                      language,
                    ),
                    style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),

                  _SectionLabel(vendorLabel('Preferences', 'Mapendeleo', language)),
                  _SettingRow(
                    icon: Icons.language_rounded,
                    label: vendorLabel('Language', 'Lugha', language),
                    value: vendor.language,
                    onTap: _chooseLanguage,
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      '${vendorLabel('Last saved', 'Ilihifadhiwa mara ya mwisho', language)} ${_formatTime(vendor.lastUpdated)}',
                      style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted),
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

String _formatTime(DateTime t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  final s = t.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

class _Hero extends StatelessWidget {
  const _Hero({required this.vendor, required this.onEditPhoto});

  final VendorProfileState vendor;
  final VoidCallback onEditPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      decoration: const BoxDecoration(
        color: AppColors.slate,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              RoundBackButton(onPressed: () => context.pop()),
              const SizedBox(width: 12),
              Expanded(child: Text(vendorLabel('Vendor settings', 'Mipangilio ya muuzaji', vendor.language), style: AppText.serif(fontSize: 22, color: AppColors.cream))),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      vendor.photoUrl.isEmpty
                          ? PlaceholderImage(label: vendor.photoLabel, circle: true)
                          : RemoteImage(url: vendor.photoUrl, fallback: vendor.photoLabel, circle: true),
                      if (vendor.uploadingProfilePhoto)
                        const DecoratedBox(
                          decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream)),
                        ),
                    ],
                  ),
                ),
                FloatingActionButton.small(
                  backgroundColor: AppColors.teal,
                  onPressed: vendor.uploadingProfilePhoto ? null : onEditPhoto,
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.cream),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(vendor.shopTitle, style: AppText.serif(fontSize: 20, color: AppColors.cream)),
          const SizedBox(height: 3),
          Text(
            vendor.isOpen
                ? '${vendorLabel('Open now', 'Wazi sasa', vendor.language)} · ${vendor.openTime} – ${vendor.closeTime}'
                : vendorLabel('Currently closed', 'Kwa sasa imefungwa', vendor.language),
            style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.66)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 11),
    child: Text(text.toUpperCase(), style: AppText.eyebrow()),
  );
}

/// A "view text + Edit link" card: shows [label]/[value] at rest, and on
/// tapping "Edit" swaps in a text box with Cancel/Save actions. Shared by
/// every free-text vendor field (shop name, bio, office address) so they
/// all edit the same way instead of always-open text fields.
class _EditableInfoCard extends StatefulWidget {
  const _EditableInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onSave,
    this.hint,
    this.maxLines = 1,
    this.footer,
    this.editLabel = 'Edit',
    this.saveLabel = 'Save',
    this.cancelLabel = 'Cancel',
  });

  final Widget icon;
  final String label;
  final String value;
  final ValueChanged<String> onSave;
  final String? hint;
  final int maxLines;
  final Widget? footer;
  final String editLabel;
  final String saveLabel;
  final String cancelLabel;

  @override
  State<_EditableInfoCard> createState() => _EditableInfoCardState();
}

class _EditableInfoCardState extends State<_EditableInfoCard> {
  bool _editing = false;
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) widget.onSave(value);
    setState(() => _editing = false);
  }

  void _cancel() {
    _controller.text = widget.value;
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(13)),
                alignment: Alignment.center,
                child: widget.icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(widget.value, style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  ],
                ),
              ),
              if (!_editing)
                InkWell(
                  onTap: () => setState(() => _editing = true),
                  child: Text(widget.editLabel, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ),
            ],
          ),
          if (_editing) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(14)),
              alignment: widget.maxLines > 1 ? Alignment.topLeft : Alignment.centerLeft,
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: widget.maxLines,
                style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                decoration: InputDecoration.collapsed(
                  hintText: widget.hint,
                  hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
              ),
            ),
            if (widget.footer != null) ...[const SizedBox(height: 10), widget.footer!],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.creamDark, width: 1.5)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _cancel,
                      child: Container(height: 44, alignment: Alignment.center, child: Text(widget.cancelLabel, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted))),
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
                      child: Container(height: 44, alignment: Alignment.center, child: Text(widget.saveLabel, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.cream))),
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

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.days, required this.onToggle});

  final List<bool> days;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < kWeekdayLabels.length; i++) ...[
          if (i != 0) const SizedBox(width: 6),
          Expanded(child: _WeekdayChip(label: kWeekdayLabels[i], active: days[i], onTap: () => onToggle(i))),
        ],
      ],
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.teal : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13), side: BorderSide(color: active ? AppColors.teal : AppColors.creamDark, width: 1.5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
            label.substring(0, 2),
            textAlign: TextAlign.center,
            style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800, color: active ? AppColors.cream : AppColors.slate),
          ),
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(16)),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 19, color: AppColors.teal),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700))),
              Text(value, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.teal)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 19, color: AppColors.muted),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isOpen, required this.onToggle, required this.language});

  final bool isOpen;
  final VoidCallback onToggle;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: isOpen ? AppColors.tealMuted : AppColors.dangerLight, borderRadius: BorderRadius.circular(999)),
            child: Text(
              isOpen ? vendorLabel('Open', 'Wazi', language) : vendorLabel('Closed', 'Imefungwa', language),
              style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: isOpen ? AppColors.teal : AppColors.danger),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isOpen
                  ? vendorLabel('Shop is currently accepting new orders', 'Duka kwa sasa linapokea oda mpya', language)
                  : vendorLabel('Shop is currently not accepting new orders', 'Duka kwa sasa halipokei oda mpya', language),
              style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          ToggleSwitch(on: isOpen, onTap: onToggle),
        ],
      ),
    );
  }
}

class _ShopPhotosStrip extends StatelessWidget {
  const _ShopPhotosStrip({required this.photos, required this.uploading, required this.onAdd, required this.onRemove});

  final List<VendorShopPhoto> photos;
  final bool uploading;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final canAdd = photos.length < 6;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length + (canAdd ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i == photos.length) {
            return InkWell(
              onTap: uploading ? null : onAdd,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark, width: 1.5), borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: uploading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal))
                    : const Icon(Icons.add_photo_alternate_outlined, color: AppColors.teal, size: 26),
              ),
            );
          }
          final photo = photos[i];
          return Stack(
            children: [
              SizedBox(width: 96, height: 96, child: RemoteImage(url: photo.url, fallback: 'Shop photo', borderRadius: 16)),
              Positioned(
                top: 5,
                right: 5,
                child: InkWell(
                  onTap: () => onRemove(i),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.label, this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark), borderRadius: BorderRadius.circular(16)),
    clipBehavior: Clip.antiAlias,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.teal),
              const SizedBox(width: 13),
              Expanded(child: Text(label, style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w700))),
              if (value != null) Text(value!, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
            ],
          ),
        ),
      ),
    ),
  );
}
