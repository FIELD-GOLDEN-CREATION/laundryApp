import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Icon+label quick-action tile for hero headers on a slate background
/// (profile screen, admin settings screen).
class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(children: [Icon(icon, size: 19, color: AppColors.cream), const SizedBox(height: 6), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.sans(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.cream))]),
      ),
    ),
  );
}
