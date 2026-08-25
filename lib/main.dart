import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/update_checker.dart';
import 'firebase_options.dart';
import 'state/client_preferences_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final container = ProviderContainer();
  container.read(clientPreferencesProvider.notifier).load();
  runApp(UncontrolledProviderScope(container: container, child: const LaundryApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) => UpdateChecker.checkForUpdate());
}
