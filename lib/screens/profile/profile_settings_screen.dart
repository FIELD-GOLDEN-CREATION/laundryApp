import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String language = 'English';
  String theme = 'Light';

  void _choose(String title, List<String> options, String value, ValueChanged<String> onChanged) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.serif(fontSize: 23)),
            const SizedBox(height: 10),
            for (final option in options) ListTile(title: Text(option, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700)), trailing: option == value ? const Icon(Icons.check_rounded, color: AppColors.teal) : null, onTap: () { onChanged(option); Navigator.pop(context); }),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Settings', style: AppText.serif(fontSize: 24)), backgroundColor: AppColors.cream, foregroundColor: AppColors.slate),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Text('PREFERENCES', style: AppText.eyebrow()),
      _SettingRow(icon: Icons.language_rounded, title: 'Language', value: language, onTap: () => _choose('Language', ['English', 'Swahili'], language, (v) => setState(() => language = v))),
      _SettingRow(icon: Icons.palette_outlined, title: 'Theme', value: theme, onTap: () => _choose('Theme', ['Light', 'Dark', 'System default'], theme, (v) => setState(() => theme = v))),
      const SizedBox(height: 24),
      Text('LEGAL', style: AppText.eyebrow()),
      _SettingRow(icon: Icons.description_outlined, title: 'Terms of service', onTap: () => _showDocument(context, 'Terms of service', 'LaundryApp helps you book pickup, cleaning and delivery services from verified shops. Orders, payments and cancellations are subject to the service terms shown at checkout.')),
      _SettingRow(icon: Icons.policy_outlined, title: 'Privacy policy', onTap: () => _showDocument(context, 'Privacy policy', 'We use your account, address and order details to provide pickup and delivery. We do not sell your personal information. Contact support to request an update or deletion.')),
    ]),
  );

  void _showDocument(BuildContext context, String title, String body) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppText.serif(fontSize: 24)),
        const SizedBox(height: 14),
        Text(body, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.55)),
      ]),
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title, this.value, required this.onTap});
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), leading: Icon(icon, color: AppColors.teal), title: Text(title, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (value != null) Text(value!, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)), const SizedBox(width: 8), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)]), onTap: onTap);
}
