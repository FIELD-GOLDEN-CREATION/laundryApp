import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/update_checker.dart';

void main() {
  runApp(const ProviderScope(child: LaundryApp()));
  WidgetsBinding.instance.addPostFrameCallback((_) => UpdateChecker.checkForUpdate());
}
