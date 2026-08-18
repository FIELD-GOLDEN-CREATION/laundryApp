import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/services/api_client.dart';
import '../models/user_role.dart';
import 'login_form_state.dart';

class AuthState {
  const AuthState({
    this.role = UserRole.guest,
    this.authEmail = '',
    this.userName = '',
    this.userPhotoUrl,
    this.isLoading = false,
  });

  final UserRole role;
  final String authEmail;
  final String userName;
  final String? userPhotoUrl;
  final bool isLoading;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  UserRole _parseRole(String role) {
    return switch (role) {
      'admin' => UserRole.admin,
      'vendor' => UserRole.vendor,
      'staff' => UserRole.staff,
      'driver' => UserRole.driver,
      _ => UserRole.customer,
    };
  }

  Future<String?> login(String email, String password) async {
    final e = email.trim().toLowerCase();
    state = const AuthState(isLoading: true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: e,
        password: password,
      );

      final idToken = await credential.user?.getIdToken(true);
      if (idToken == null) {
        state = const AuthState();
        return 'Failed to get authentication token.';
      }

      final response = await ApiClient.post('/auth/login', body: {
        'id_token': idToken,
      });

      if (response['success'] == true) {
        final userData = response['user'] as Map<String, dynamic>;
        final role = _parseRole(userData['role'] as String);
        ApiClient.setToken(response['token'] as String);
        state = AuthState(
          role: role,
          authEmail: e,
          userName: userData['name'] as String? ?? '',
          userPhotoUrl: userData['photo_url'] as String?,
        );
        return null;
      } else {
        await FirebaseAuth.instance.signOut();
        state = const AuthState();
        return response['message'] as String? ?? 'Login failed.';
      }
    } on FirebaseAuthException catch (e) {
      state = const AuthState();
      return _firebaseAuthErrorMessage(e);
    } catch (e) {
      state = const AuthState();
      return 'Unable to connect to server. Please try again.';
    }
  }

  Future<String?> loginWithGoogle() async {
    state = const AuthState(isLoading: true);

    try {
      final googleUser = await GoogleSignIn(scopes: ['email', 'profile']).signIn();
      if (googleUser == null) {
        state = const AuthState();
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken(true);

      if (idToken == null) {
        state = const AuthState();
        return 'Failed to get authentication token.';
      }

      final response = await ApiClient.post('/auth/login', body: {
        'id_token': idToken,
      });

      if (response['success'] == true) {
        final userData = response['user'] as Map<String, dynamic>;
        final role = _parseRole(userData['role'] as String);
        ApiClient.setToken(response['token'] as String);
        state = AuthState(
          role: role,
          authEmail: userData['email'] as String? ?? '',
          userName: userData['name'] as String? ?? '',
          userPhotoUrl: userData['photo_url'] as String?,
        );
        return null;
      } else {
        await FirebaseAuth.instance.signOut();
        state = const AuthState();
        return response['message'] as String? ?? 'Login failed.';
      }
    } on FirebaseAuthException catch (e) {
      state = const AuthState();
      return _firebaseAuthErrorMessage(e);
    } catch (e) {
      state = const AuthState();
      return 'Google sign-in failed. Please try again.';
    }
  }

  Future<String?> registerClient({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final e = email.trim().toLowerCase();
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      return 'Complete all account details.';
    }
    if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(e)) {
      return 'Enter a valid email address.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: e,
        password: password,
      );

      await credential.user?.updateDisplayName(name);

      final idToken = await credential.user?.getIdToken(true);
      if (idToken == null) {
        state = const AuthState();
        return 'Failed to get authentication token.';
      }

      final response = await ApiClient.post('/auth/register', body: {
        'id_token': idToken,
        'phone': phone,
      });

      if (response['success'] == true) {
        final userData = response['user'] as Map<String, dynamic>;
        final role = _parseRole(userData['role'] as String);
        ApiClient.setToken(response['token'] as String);
        state = AuthState(
          role: role,
          authEmail: e,
          userName: name,
        );
        return null;
      } else {
        await FirebaseAuth.instance.currentUser?.delete();
        state = const AuthState();
        return response['message'] as String? ?? 'Registration failed.';
      }
    } on FirebaseAuthException catch (e) {
      state = const AuthState();
      return _firebaseAuthErrorMessage(e);
    } catch (e) {
      state = const AuthState();
      return 'Unable to connect to server. Please try again.';
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
    ApiClient.setToken(null);
    state = const AuthState();
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-credential':
        return 'Invalid credentials.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

String roleHomePath(UserRole role) => switch (role) {
  UserRole.admin => '/admin/dashboard',
  UserRole.vendor => '/vendor/dashboard',
  UserRole.staff => '/staff/dashboard',
  UserRole.driver => '/staff/dashboard',
  UserRole.customer || UserRole.guest => '/home',
};

bool gateGuest(
  WidgetRef ref,
  BuildContext context,
  String reason, {
  String? redirectPath,
  Object? redirectExtra,
}) {
  if (ref.read(authProvider).role != UserRole.guest) return false;
  ref.read(loginFormProvider.notifier).setReason(reason, redirectPath: redirectPath, redirectExtra: redirectExtra);
  context.push('/login');
  return true;
}
