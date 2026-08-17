import 'package:flutter/material.dart';

import '../core/icons/app_icons.dart';
import '../theme/colors.dart';

/// The small rounded back-chevron button reused at the top of every flow
/// screen (Search, Detail, Cart, Schedule, Checkout, Notifications).
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: Material(
        color: AppColors.clientSurface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.clientBorder(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: Center(child: AppIcon(AppIcons.backChevron, size: 9, color: AppColors.clientText(context))),
        ),
      ),
    );
  }
}
