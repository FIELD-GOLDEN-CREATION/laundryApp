import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_role.dart';
import '../state/auth_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// The account bottom-sheet triggered by the "V"/"A" corner button on the
/// Vendor/Admin dashboards (ports the source's `sheetOpen`). Only ever
/// shown to an already-authed vendor/admin — there's no guest variant here
/// since a guest can't reach those dashboards in the first place.
void showAccountSheet(BuildContext context, WidgetRef ref) {
  final auth = ref.read(authProvider);
  final isAdmin = auth.role == UserRole.admin;
  final isDriver = auth.role == UserRole.driver;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(color: const Color(0xFFDED8CA), borderRadius: BorderRadius.circular(99)),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isAdmin ? AppColors.creamDark : (isDriver ? AppColors.successLight : AppColors.amberLight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isAdmin ? 'A' : (isDriver ? 'D' : 'V'),
                    style: AppText.serif(
                      fontSize: 20,
                      color: isAdmin ? AppColors.slate : (isDriver ? AppColors.success : AppColors.amber),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdmin ? 'Site Administrator' : (isDriver ? 'Kofi Asante' : 'Marina Fresh Laundry'),
                        style: AppText.serif(fontSize: 20),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${auth.authEmail} · ${isAdmin ? 'Admin' : (isDriver ? 'Driver' : 'Vendor')} account',
                        style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(roleHomePath(auth.role));
                  },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    child: Text(
                      isAdmin ? 'Go to command center' : (isDriver ? 'Go to shift' : 'Go to dashboard'),
                      style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.cream),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
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
                    Navigator.of(sheetContext).pop();
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
      );
    },
  );
}
