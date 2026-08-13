import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/admin_mock_data.dart';
import '../../state/admin_settings_state.dart';
import '../../state/auth_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/toggle_switch.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  // No external mutation happens to these fields (unlike coordQuery's
  // "Locate me" or the login form's demo-fill buttons), so a one-time read
  // for the initial value is enough — no ref.listen resync needed.
  late final _emailController = TextEditingController(text: ref.read(adminSettingsProvider).emailField);
  late final _pw1Controller = TextEditingController();
  late final _pw2Controller = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _pw1Controller.dispose();
    _pw2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSettingsProvider);
    final notifier = ref.read(adminSettingsProvider.notifier);
    final authEmail = ref.watch(authProvider).authEmail;
    final emailShown = authEmail.isEmpty ? 'admin@gmail.com' : authEmail;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Admin settings', style: AppText.serif(fontSize: 27)),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 66, height: 66, child: PlaceholderImage(label: 'Admin photo', borderRadius: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Site Administrator', style: AppText.serif(fontSize: 21)),
                      const SizedBox(height: 2),
                      Text(
                        emailShown,
                        style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11), side: const BorderSide(color: AppColors.creamDark)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            child: Text('Change photo', style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.teal)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REGISTERED EMAIL', style: AppText.eyebrow()),
                  const SizedBox(height: 8),
                  _Field(controller: _emailController, onChanged: notifier.setEmailField),
                  const SizedBox(height: 16),
                  Text('NEW PASSWORD', style: AppText.eyebrow()),
                  const SizedBox(height: 8),
                  _Field(controller: _pw1Controller, onChanged: notifier.setPassword1, hint: '••••••••', obscure: true),
                  const SizedBox(height: 16),
                  Text('CONFIRM PASSWORD', style: AppText.eyebrow()),
                  const SizedBox(height: 8),
                  _Field(controller: _pw2Controller, onChanged: notifier.setPassword2, hint: '••••••••', obscure: true),
                  const SizedBox(height: 16),
                  Material(
                    color: state.pwSaved ? AppColors.tealMuted : AppColors.teal,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: notifier.savePassword,
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        alignment: Alignment.center,
                        child: Text(
                          state.pwSaved ? '✓ Changes saved' : 'Save changes',
                          style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: state.pwSaved ? AppColors.teal : AppColors.cream),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const _SectionLabel('Staff permissions'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < kPermissionLabels.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: i == kPermissionLabels.length - 1 ? Colors.transparent : AppColors.cream)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(kPermissionLabels[i].$1, style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(
                                  kPermissionLabels[i].$2,
                                  style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          ToggleSwitch(on: state.permissionsOn[i], onTap: () => notifier.togglePermission(i)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const _SectionLabel('Notifications'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.creamDark),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < kNotificationToggleLabels.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: i == kNotificationToggleLabels.length - 1 ? Colors.transparent : AppColors.cream)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(kNotificationToggleLabels[i], style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800)),
                          ),
                          ToggleSwitch(on: state.notificationsOn[i], onTap: () => notifier.toggleNotification(i)),
                        ],
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

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.onChanged, this.hint = '', this.obscure = false});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        obscureText: obscure,
        style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
        decoration: InputDecoration.collapsed(
          hintText: hint,
          hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
        ),
      ),
    );
  }
}
