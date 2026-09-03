import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// The pill toggle switch reused across Profile preferences, the Vendor
/// catalog's category/add-on toggles, and Admin settings' permission/
/// notification toggles (ported from the source's repeated inline pattern).
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({super.key, required this.on, required this.onTap, this.enabled = true});

  final bool on;
  final VoidCallback onTap;

  /// When false, the switch renders greyed out (e.g. an admin-locked
  /// package) but [onTap] still fires — callers use that to explain why
  /// instead of leaving the tap inert.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 46,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: !enabled
              ? const Color(0xFFE8E4D9)
              : (on ? AppColors.teal : const Color(0xFFD7D2C6)),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF5F0E8),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 3, offset: const Offset(0, 1))],
          ),
        ),
      ),
    );
  }
}
