import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Login screen's own transient field state — kept separate from
/// [authProvider] (the committed role), same split as the rest of the app
/// (e.g. cart quantities vs. checkout's promo field).
class LoginFormState {
  const LoginFormState({
    this.email = '',
    this.password = '',
    this.error = '',
    this.reason = '',
    this.redirectPath,
    this.redirectExtra,
  });

  final String email;
  final String password;
  final String error;
  final String reason;

  /// Where a guest was headed when they got gated — e.g. `/detail` for a
  /// shop they tapped. Consumed by LoginScreen on a successful login so the
  /// guest lands where they left off instead of just their role's home.
  final String? redirectPath;
  final Object? redirectExtra;

  LoginFormState copyWith({String? email, String? password, String? error, String? reason}) => LoginFormState(
    email: email ?? this.email,
    password: password ?? this.password,
    error: error ?? this.error,
    reason: reason ?? this.reason,
    redirectPath: redirectPath,
    redirectExtra: redirectExtra,
  );
}

class LoginFormNotifier extends Notifier<LoginFormState> {
  @override
  LoginFormState build() => const LoginFormState();

  void setEmail(String v) => state = state.copyWith(email: v, error: '');
  void setPassword(String v) => state = state.copyWith(password: v, error: '');
  void setError(String v) => state = state.copyWith(error: v);

  /// Sets the gate reason shown on Login, plus where to send the user back
  /// to once they've logged in. [redirectPath]/[redirectExtra] replace
  /// whatever was previously stashed (each gate call targets its own spot).
  void setReason(String v, {String? redirectPath, Object? redirectExtra}) => state = LoginFormState(
    email: state.email,
    password: state.password,
    reason: v,
    redirectPath: redirectPath,
    redirectExtra: redirectExtra,
  );

  void fillCustomer() => state = state.copyWith(email: 'user@gmail.com', password: 'user04', error: '');
  void fillVendor() => state = state.copyWith(email: 'vendor@gmail.com', password: 'vendor04', error: '');
  void fillAdmin() => state = state.copyWith(email: 'admin@gmail.com', password: 'admin04', error: '');
  void fillStaff() => state = state.copyWith(email: 'staff@gmail.com', password: 'staff04', error: '');

  void reset() => state = const LoginFormState();
}

final loginFormProvider = NotifierProvider<LoginFormNotifier, LoginFormState>(LoginFormNotifier.new);
