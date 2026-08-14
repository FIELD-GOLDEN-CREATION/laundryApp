import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../data/vendor_mock_data.dart';
import '../../state/vendor_profile_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/round_back_button.dart';
import '../../widgets/toggle_switch.dart';

/// The vendor-facing settings hub, reached from the account sheet's
/// "Settings" button. Mirrors the layout/design language of
/// `screens/profile/profile_screen.dart` (hero header + eyebrow section
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
                    for (final option in kVendorTimeOptions)
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

  @override
  Widget build(BuildContext context) {
    final vendor = ref.watch(vendorProfileProvider);
    final notifier = ref.read(vendorProfileProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            _Hero(vendor: vendor, onEditPhoto: notifier.cyclePhotoLabel),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Shop details'),
                  _EditableInfoCard(
                    icon: const Icon(Icons.storefront_outlined, size: 17, color: AppColors.teal),
                    label: 'Shop name',
                    value: vendor.shopTitle,
                    hint: 'Enter shop name',
                    onSave: notifier.updateShopTitle,
                  ),
                  _EditableInfoCard(
                    icon: const Icon(Icons.notes_rounded, size: 17, color: AppColors.teal),
                    label: 'Bio',
                    value: vendor.bio,
                    hint: 'Tell customers about your shop',
                    maxLines: 4,
                    onSave: notifier.updateBio,
                  ),

                  const _SectionLabel('Location'),
                  _EditableInfoCard(
                    icon: const AppIcon(AppIcons.office, size: 16, color: AppColors.teal),
                    label: 'Office address',
                    value: vendor.officeAddress,
                    hint: 'Enter office address',
                    onSave: notifier.updateOfficeAddress,
                    footer: InkWell(
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Google Maps location picker coming soon')),
                      ),
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
                  ),

                  const _SectionLabel('Working schedule'),
                  _WeekdayPicker(days: vendor.workingDays, onToggle: notifier.toggleWorkingDay),
                  const SizedBox(height: 10),
                  _TimeRow(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Opens at',
                    value: vendor.openTime,
                    onTap: () => _chooseTime('Opening time', vendor.openTime, notifier.updateOpenTime),
                  ),
                  const SizedBox(height: 8),
                  _TimeRow(
                    icon: Icons.nights_stay_outlined,
                    label: 'Closes at',
                    value: vendor.closeTime,
                    onTap: () => _chooseTime('Closing time', vendor.closeTime, notifier.updateCloseTime),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vendor.scheduleSummary,
                    style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),

                  const _SectionLabel('Shop status'),
                  _StatusCard(isOpen: vendor.isOpen, onToggle: notifier.toggleOpen),

                  _SectionLabel('Shop photos (${vendor.shopPhotoLabels.length}/6)'),
                  _ShopPhotosStrip(
                    labels: vendor.shopPhotoLabels,
                    onAdd: notifier.addShopPhoto,
                    onRemove: notifier.removeShopPhoto,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Shown to customers as a slideshow on your shop page, 4s per photo.',
                    style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),

                  const _SectionLabel('Preferences'),
                  _SettingRow(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    value: vendor.language,
                    onTap: () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Language options coming soon'))),
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Last saved ${_formatTime(vendor.lastUpdated)}',
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
              Expanded(child: Text('Vendor settings', style: AppText.serif(fontSize: 22, color: AppColors.cream))),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                SizedBox(width: 96, height: 96, child: PlaceholderImage(label: vendor.photoLabel, circle: true)),
                FloatingActionButton.small(
                  backgroundColor: AppColors.teal,
                  onPressed: onEditPhoto,
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.cream),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(vendor.shopTitle, style: AppText.serif(fontSize: 20, color: AppColors.cream)),
          const SizedBox(height: 3),
          Text(
            vendor.isOpen ? 'Open now · ${vendor.openTime} – ${vendor.closeTime}' : 'Currently closed',
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
  });

  final Widget icon;
  final String label;
  final String value;
  final ValueChanged<String> onSave;
  final String? hint;
  final int maxLines;
  final Widget? footer;

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
                  child: Text('Edit', style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
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
                      child: Container(height: 44, alignment: Alignment.center, child: Text('Cancel', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.muted))),
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
                      child: Container(height: 44, alignment: Alignment.center, child: Text('Save', style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.cream))),
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
  const _StatusCard({required this.isOpen, required this.onToggle});

  final bool isOpen;
  final VoidCallback onToggle;

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
              isOpen ? 'Open' : 'Closed',
              style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: isOpen ? AppColors.teal : AppColors.danger),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Shop is currently ${isOpen ? 'accepting' : 'not accepting'} new orders',
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
  const _ShopPhotosStrip({required this.labels, required this.onAdd, required this.onRemove});

  final List<String> labels;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length + (labels.length < 6 ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i == labels.length) {
            return InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.creamDark, width: 1.5), borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.teal, size: 26),
              ),
            );
          }
          return Stack(
            children: [
              SizedBox(width: 96, height: 96, child: PlaceholderImage(label: labels[i], borderRadius: 16)),
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
