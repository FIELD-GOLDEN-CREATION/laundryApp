import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/auth_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          children: [
            Text('Profile', style: AppText.serif(fontSize: 27)),
            const SizedBox(height: 20),

            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.tealMuted,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'SA',
                      style: AppText.sans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.teal),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Staff Admin', style: AppText.sans(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('Mama Ngina Branch', style: AppText.sans(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            Row(
              children: [
                _ProfileStat(value: '142', label: 'Orders\nChecked In'),
                const SizedBox(width: 12),
                _ProfileStat(value: '3.2 yrs', label: 'Staff\nTenure'),
                const SizedBox(width: 12),
                _ProfileStat(value: '4.8', label: 'Customer\nRating'),
              ],
            ),
            const SizedBox(height: 28),

            _ProfileMenuItem(icon: Icons.person_outline, label: 'Edit Profile', onTap: () {}),
            _ProfileMenuItem(icon: Icons.lock_outline, label: 'Change PIN', onTap: () {}),
            _ProfileMenuItem(icon: Icons.schedule_outlined, label: 'Shift History', onTap: () {}),
            _ProfileMenuItem(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Sign Out',
                  style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.danger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.creamDark),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(value, style: AppText.sans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.slate)),
            const SizedBox(height: 4),
            Text(label, style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.creamDark),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.slate, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
