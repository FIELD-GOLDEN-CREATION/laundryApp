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

    test('logs in each of the demo accounts to the right role', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(authProvider.notifier);

      expect(notifier.login('user@gmail.com', 'user04'), isNull);
      expect(container.read(authProvider).role, UserRole.customer);

      expect(notifier.login('vendor@gmail.com', 'vendor04'), isNull);
      expect(container.read(authProvider).role, UserRole.vendor);
    });

    test('login is case-insensitive on email and trims whitespace', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(authProvider.notifier);

      expect(notifier.login('  USER@Gmail.com  ', 'user04'), isNull);
      expect(container.read(authProvider).role, UserRole.customer);
    });

    test('bad credentials return an error and leave role as guest', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(authProvider.notifier);

      final error = notifier.login('user@gmail.com', 'wrong');
      expect(error, isNotNull);
      expect(container.read(authProvider).role, UserRole.guest);
    });

    test('logout resets to guest', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(authProvider.notifier);

      notifier.login('vendor@gmail.com', 'vendor04');
      notifier.logout();
      expect(container.read(authProvider).role, UserRole.guest);
      expect(container.read(authProvider).authEmail, '');
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
