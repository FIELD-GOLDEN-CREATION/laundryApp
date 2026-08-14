import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/client_preferences_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {

  void _choose(String title, List<String> options, String value, ValueChanged<String> onChanged) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
  Widget build(BuildContext context) {
    final preferences = ref.watch(clientPreferencesProvider);
    final language = preferences.language;
    final theme = preferences.dark ? 'Dark' : 'Light';
    return Scaffold(
    appBar: AppBar(title: Text(clientLabel('Settings', 'Mipangilio', language), style: AppText.serif(fontSize: 24))),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Text(clientLabel('PREFERENCES', 'MAPENDEKEZO', language), style: AppText.eyebrow()),
      _SettingRow(icon: Icons.language_rounded, title: clientLabel('Language', 'Lugha', language), value: language, onTap: () => _choose('Language', ['English', 'Swahili'], language, (v) => ref.read(clientPreferencesProvider.notifier).setLanguage(v))),
      _SettingRow(icon: Icons.palette_outlined, title: clientLabel('Theme', 'Mandhari', language), value: theme, onTap: () => _choose('Theme', ['Light', 'Dark'], theme, (v) => ref.read(clientPreferencesProvider.notifier).setTheme(v))),
      const SizedBox(height: 24),
      Text(clientLabel('LEGAL', 'KISHERIA', language), style: AppText.eyebrow()),
      _SettingRow(icon: Icons.description_outlined, title: clientLabel('Terms of service', 'Masharti ya huduma', language), onTap: () => _showDocument(context, clientLabel('Terms of service', 'Masharti ya huduma', language), clientLabel('LaundryApp helps you book pickup, cleaning and delivery services from verified shops. Orders, payments and cancellations are subject to the service terms shown at checkout.', 'LaundryApp hukusaidia kuagiza kuchukua, kufua na kupeleka nguo kutoka maduka yaliyothibitishwa. Oda, malipo na kughairi vinafuata masharti yanayoonyeshwa wakati wa kuagiza.', language))),
      _SettingRow(icon: Icons.policy_outlined, title: clientLabel('Privacy policy', 'Sera ya faragha', language), onTap: () => _showDocument(context, clientLabel('Privacy policy', 'Sera ya faragha', language), clientLabel('We use your account, address and order details to provide pickup and delivery. We do not sell your personal information. Contact support to request an update or deletion.', 'Tunatumia taarifa za akaunti, anwani na oda kutoa huduma ya kuchukua na kupeleka. Hatuuzi taarifa zako binafsi.', language))),
    ]),
    );
  }

  void _showDocument(BuildContext context, String title, String body) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
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
