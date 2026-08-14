import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin_mock_data.dart';
import '../../state/admin_settings_state.dart';
import '../../state/auth_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/placeholder_image.dart';
import '../../widgets/profile_action_tile.dart';
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

  final _securityKey = GlobalKey();
  final _staffKey = GlobalKey();
  final _alertsKey = GlobalKey();

  @override
  void dispose() {
    _emailController.dispose();
    _pw1Controller.dispose();
    _pw2Controller.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut, alignment: 0.05);
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
                  Row(children: [Expanded(child: Text('Admin settings', style: AppText.serif(fontSize: 24, color: AppColors.cream)))]),
                  const SizedBox(height: 18),
                  const SizedBox(width: 82, height: 82, child: PlaceholderImage(label: 'Admin photo', circle: true)),
                  const SizedBox(height: 11),
                  Text('Site Administrator', style: AppText.serif(fontSize: 23, color: AppColors.cream)),
                  const SizedBox(height: 3),
                  Text(emailShown, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cream.withValues(alpha: 0.66))),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11), side: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Text('Change photo', style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.cream)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ProfileActionTile(
                          icon: Icons.lock_outline_rounded,
                          label: 'Security',
                          onTap: () => _scrollTo(_securityKey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ProfileActionTile(
                          icon: Icons.groups_outlined,
                          label: 'Staff',
                          onTap: () => _scrollTo(_staffKey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ProfileActionTile(
                          icon: Icons.notifications_none_rounded,
                          label: 'Alerts',
                          onTap: () => _scrollTo(_alertsKey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              child: Column(
                children: [
                  Container(
                    key: _securityKey,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.creamDark),
                      borderRadius: BorderRadius.circular(20),
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
                    key: _staffKey,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.creamDark),
                      borderRadius: BorderRadius.circular(20),
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
                    key: _alertsKey,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.creamDark),
                      borderRadius: BorderRadius.circular(20),
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
