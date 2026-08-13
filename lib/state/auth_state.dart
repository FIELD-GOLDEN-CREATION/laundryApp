import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_role.dart';
import 'login_form_state.dart';

class AuthState {
  const AuthState({this.role = UserRole.guest, this.authEmail = ''});

  final UserRole role;
  final String authEmail;
}

/// Ports the source's `role`/`authEmail` fields + `doLogin`/`doLogout`.
/// In-memory only, no persistence — same as the source (no backend).
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  static const _accounts = {
    'admin@gmail.com': ('admin04', UserRole.admin),
    'vendor@gmail.com': ('vendor04', UserRole.vendor),
    'user@gmail.com': ('user04', UserRole.customer),
    'driver@gmail.com': ('driver04', UserRole.driver),
  };

  /// Returns null on success, or an error message to show on the form.
  String? login(String email, String password) {
    final e = email.trim().toLowerCase();
    final match = _accounts[e];
    if (match != null && match.$1 == password) {
      state = AuthState(role: match.$2, authEmail: e);
      return null;
    }
    return 'That email and password combination is not recognised.';
  }

  void logout() => state = const AuthState();
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

String roleHomePath(UserRole role) => switch (role) {
  UserRole.admin => '/admin/dashboard',
  UserRole.vendor => '/vendor/dashboard',
  UserRole.driver => '/driver/dash',
  UserRole.customer || UserRole.guest => '/home',
};

/// The source's `gate(screen, reason)`: if still a guest, stash [reason] on
/// the login form and push Login; otherwise do nothing and let the caller
/// proceed with its own authed-path action. Returns true when the guest was
/// redirected (callers should stop / not run their normal action).
///
/// [redirectPath]/[redirectExtra], when given, are where the guest was
/// actually headed (e.g. a shop's `/detail`) — LoginScreen sends them there
/// on a successful login instead of just their role's home, so they land
/// back where they left off.
bool gateGuest(
  WidgetRef ref,
  BuildContext context,
  String reason, {
  String? redirectPath,
  Object? redirectExtra,
}) {
  if (ref.read(authProvider).role != UserRole.guest) return false;
  ref.read(loginFormProvider.notifier).setReason(reason, redirectPath: redirectPath, redirectExtra: redirectExtra);
  context.push('/login');
  return true;
}
