import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_mock_data.dart';

class AdminSettingsState {
  const AdminSettingsState({
    this.emailField = 'admin@gmail.com',
    this.password1 = '',
    this.password2 = '',
    this.pwSaved = false,
    this.permissionsOn = kDefaultPermissionsOn,
    this.notificationsOn = kDefaultNotificationsOn,
  });

  final String emailField;
  final String password1;
  final String password2;
  final bool pwSaved;
  final List<bool> permissionsOn;
  final List<bool> notificationsOn;

  AdminSettingsState copyWith({
    String? emailField,
    String? password1,
    String? password2,
    bool? pwSaved,
    List<bool>? permissionsOn,
    List<bool>? notificationsOn,
  }) => AdminSettingsState(
    emailField: emailField ?? this.emailField,
    password1: password1 ?? this.password1,
    password2: password2 ?? this.password2,
    pwSaved: pwSaved ?? this.pwSaved,
    permissionsOn: permissionsOn ?? this.permissionsOn,
    notificationsOn: notificationsOn ?? this.notificationsOn,
  );
}

/// Ports the source's `adminEmailField`/`adminPw1`/`adminPw2`/`pwSaved`/
/// `permOn[]`/`nSoundOn[]`.
class AdminSettingsNotifier extends Notifier<AdminSettingsState> {
  @override
  AdminSettingsState build() => const AdminSettingsState();

  void setEmailField(String v) => state = state.copyWith(emailField: v, pwSaved: false);
  void setPassword1(String v) => state = state.copyWith(password1: v, pwSaved: false);
  void setPassword2(String v) => state = state.copyWith(password2: v, pwSaved: false);
  void savePassword() => state = state.copyWith(pwSaved: true);

  void togglePermission(int i) {
    final next = List.of(state.permissionsOn);
    next[i] = !next[i];
    state = state.copyWith(permissionsOn: next);
  }

  void toggleNotification(int i) {
    final next = List.of(state.notificationsOn);
    next[i] = !next[i];
    state = state.copyWith(notificationsOn: next);
  }
}

final adminSettingsProvider = NotifierProvider<AdminSettingsNotifier, AdminSettingsState>(AdminSettingsNotifier.new);
