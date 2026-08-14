import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClientPreferencesState {
  const ClientPreferencesState({this.dark = false, this.language = 'English'});
  final bool dark;
  final String language;

  ClientPreferencesState copyWith({bool? dark, String? language}) => ClientPreferencesState(
    dark: dark ?? this.dark,
    language: language ?? this.language,
  );
}

class ClientPreferencesNotifier extends Notifier<ClientPreferencesState> {
  @override
  ClientPreferencesState build() => const ClientPreferencesState();

  void setTheme(String value) => state = state.copyWith(dark: value == 'Dark');
  void setLanguage(String value) => state = state.copyWith(language: value);
}

final clientPreferencesProvider = NotifierProvider<ClientPreferencesNotifier, ClientPreferencesState>(ClientPreferencesNotifier.new);

String clientLabel(String english, String swahili, String language) => language == 'Swahili' ? swahili : english;
