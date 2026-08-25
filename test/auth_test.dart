import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laundry_app/models/user_role.dart';
import 'package:laundry_app/state/auth_state.dart';

void main() {
  group('AuthNotifier', () {
    test('starts as guest', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(authProvider).role, UserRole.guest);
    });

    test('initial state has empty email and name', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(authProvider);
      expect(state.authEmail, '');
      expect(state.userName, '');
      expect(state.isLoading, isFalse);
    });
  });

  group('roleHomePath', () {
    test('maps each role to its shell root', () {
      expect(roleHomePath(UserRole.guest), '/home');
      expect(roleHomePath(UserRole.customer), '/home');
      expect(roleHomePath(UserRole.vendor), '/vendor/dashboard');
    });
  });
}
