import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// The sticky bottom CTA button shown on Detail/Cart/Schedule/Checkout,
/// each screen supplying its own label/hint/action — mirrors the source's
/// per-screen `ctaMap` entry.
class PrimaryCtaBar extends StatelessWidget {
  const PrimaryCtaBar({super.key, required this.label, this.hint, required this.onPressed});

  final String label;
  final String? hint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cream.withValues(alpha: 0), AppColors.cream],
          stops: const [0, 0.32],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: AppColors.teal,
          borderRadius: BorderRadius.circular(20),
          elevation: 10,
          shadowColor: AppColors.teal.withValues(alpha: 0.28),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppText.sans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cream,
                  ),
                ),
                if (hint != null && hint!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Text(
                    hint!,
                    style: AppText.sans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
