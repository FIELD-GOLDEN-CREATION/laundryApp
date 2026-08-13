import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// The dot + label/sub selectable card pattern reused by Schedule's address
/// picker and Checkout's payment picker (ports the source's `sel()` helper).
class RadioOptionCard extends StatelessWidget {
  const RadioOptionCard({
    super.key,
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  /// Optional widget (e.g. a card thumbnail or mobile-money logo) rendered
  /// before the radio dot, right after it — absent in the base design.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.tealMuted : Colors.white;
    final border = selected ? AppColors.teal : AppColors.creamDark;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? AppColors.teal : const Color(0xFFCBD5CF), width: 2),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted),
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
}
