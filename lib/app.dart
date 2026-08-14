import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'models/user_role.dart';
import 'state/auth_state.dart';
import 'state/client_preferences_state.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';

/// Widest the app's phone-shaped layout is allowed to stretch on Web. Past
/// this, content is centered in a fixed-width column rather than stretching
/// full-bleed across a desktop browser tab — the source design is a fixed
/// 390x844 phone layout, so this is the equivalent for a browser window.
const _kWebMaxWidth = 480.0;

class LaundryApp extends ConsumerWidget {
  const LaundryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(clientPreferencesProvider);
    final isClient = ref.watch(authProvider).role == UserRole.customer;
    return MaterialApp.router(
      title: 'Laundry',
      debugShowCheckedModeBanner: false,
      theme: isClient && preferences.dark ? clientDarkTheme : appTheme,
      themeAnimationDuration: const Duration(milliseconds: 450),
      themeAnimationCurve: Curves.easeInOutCubic,
      routerConfig: appRouter,
      builder: (context, child) {
        if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth <= _kWebMaxWidth) return child;
            return ColoredBox(
              color: const Color(0xFFE6E2DA),
              child: Center(
                child: SizedBox(
                  width: _kWebMaxWidth,
                  height: constraints.maxHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 60, offset: const Offset(0, 24))],
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
