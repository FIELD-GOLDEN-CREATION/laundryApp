import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDarkKey = 'prefs_dark';
const _kLangKey = 'prefs_language';
const _kPrefsOnKey = 'prefs_notifications';

class ClientPreferencesState {
  const ClientPreferencesState({this.dark = false, this.language = 'English', this.prefsOn = const [true, true, false]});
  final bool dark;
  final String language;
  final List<bool> prefsOn;

  ClientPreferencesState copyWith({bool? dark, String? language, List<bool>? prefsOn}) => ClientPreferencesState(
    dark: dark ?? this.dark,
    language: language ?? this.language,
    prefsOn: prefsOn ?? this.prefsOn,
  );
}

class ClientPreferencesNotifier extends Notifier<ClientPreferencesState> {
  @override
  ClientPreferencesState build() => const ClientPreferencesState();

  /// Load persisted preferences from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(_kDarkKey) ?? false;
    final lang = prefs.getString(_kLangKey) ?? 'English';
    final prefsOnRaw = prefs.getStringList(_kPrefsOnKey);
    final prefsOn = prefsOnRaw?.map((s) => s == 'true').toList() ?? const [true, true, false];
    state = state.copyWith(dark: dark, language: lang, prefsOn: prefsOn);
  }

  void setTheme(String value) async {
    state = state.copyWith(dark: value == 'Dark');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkKey, state.dark);
  }

  void setLanguage(String value) async {
    state = state.copyWith(language: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, value);
  }

  void togglePref(int i) async {
    final next = List.of(state.prefsOn);
    next[i] = !next[i];
    state = state.copyWith(prefsOn: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPrefsOnKey, next.map((b) => b.toString()).toList());
  }
}

final clientPreferencesProvider = NotifierProvider<ClientPreferencesNotifier, ClientPreferencesState>(ClientPreferencesNotifier.new);

String clientLabel(String english, String swahili, String language) => language == 'Swahili' ? swahili : english;
