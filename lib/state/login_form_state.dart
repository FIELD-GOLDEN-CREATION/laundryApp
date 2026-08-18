import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  void setReason(String v, {String? redirectPath, Object? redirectExtra}) => state = LoginFormState(
    email: state.email,
    password: state.password,
    reason: v,
    redirectPath: redirectPath,
    redirectExtra: redirectExtra,
  );

  void reset() => state = const LoginFormState();
}

final loginFormProvider = NotifierProvider<LoginFormNotifier, LoginFormState>(LoginFormNotifier.new);
