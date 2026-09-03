import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/update_checker.dart';
import 'firebase_options.dart';
import 'state/auth_state.dart';
import 'state/client_preferences_state.dart';

class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _touchLastActive();
    }
  }

  Future<void> _touchLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kLastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final container = ProviderContainer();
  container.read(clientPreferencesProvider.notifier).load();
  runApp(
    UncontrolledProviderScope(container: container, child: const LaundryApp()),
  );
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => UpdateChecker.checkForUpdate(),
  );
}
