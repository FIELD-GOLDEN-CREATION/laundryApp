import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';
import '../services/api_service.dart';
import 'login_form_state.dart';

const _kSessionExpiry = Duration(days: 90);
const kLastActiveKey = 'last_active_timestamp';

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
  AuthState build() {
    _restoreSession();
    return const AuthState(isLoading: true);
  }

  Future<void> _restoreSession() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        state = const AuthState();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastActive = prefs.getInt(kLastActiveKey);
      if (lastActive != null) {
        final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(lastActive);
        if (DateTime.now().difference(lastActiveDate) > _kSessionExpiry) {
          await logout();
          return;
        }
      }

      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) {
        state = const AuthState();
        return;
      }

      final response = await api.login(idToken);
      if (response['success'] == true) {
        final userData = response['user'] as Map<String, dynamic>;
        final role = _parseRole(userData['role'] as String);
        state = AuthState(
          role: role,
          authEmail: firebaseUser.email ?? '',
          userName: userData['name'] as String? ?? firebaseUser.displayName ?? '',
          userPhotoUrl: userData['photo_url'] as String? ?? firebaseUser.photoURL,
        );
        await prefs.setInt(kLastActiveKey, DateTime.now().millisecondsSinceEpoch);
      } else {
        state = const AuthState();
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  UserRole _parseRole(String role) {
    return switch (role) {
      'vendor' => UserRole.vendor,
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

      final response = await api.login(idToken);

      if (response['success'] == true) {
        final userData = response['user'] as Map<String, dynamic>;
        final role = _parseRole(userData['role'] as String);
        state = AuthState(
          role: role,
          authEmail: e,
          userName: userData['name'] as String? ?? '',
          userPhotoUrl: userData['photo_url'] as String?,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(kLastActiveKey, DateTime.now().millisecondsSinceEpoch);
        return null;
      } else {
        await FirebaseAuth.instance.signOut();
        state = const AuthState();
        return response['message'] as String? ?? 'Login failed.';
      }
    } on FirebaseAuthException catch (e) {
      state = const AuthState();
      return _firebaseAuthErrorMessage(e);
    } on ApiException catch (e) {
      state = const AuthState();
      return e.message;
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

      final response = await api.login(idToken);

      if (response['success'] == true) {
        final userData = response['user'] as Map<String, dynamic>;
        final role = _parseRole(userData['role'] as String);
        state = AuthState(
          role: role,
          authEmail: userData['email'] as String? ?? '',
          userName: userData['name'] as String? ?? '',
          userPhotoUrl: userData['photo_url'] as String?,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(kLastActiveKey, DateTime.now().millisecondsSinceEpoch);
        return null;
      } else {
        await FirebaseAuth.instance.signOut();
        state = const AuthState();
        return response['message'] as String? ?? 'Login failed.';
      }
    } on FirebaseAuthException catch (e) {
      state = const AuthState();
      return _firebaseAuthErrorMessage(e);
    } on ApiException catch (e) {
      state = const AuthState();
      return e.message;
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

      final response = await api.register(idToken, phone: phone);

      if (response['success'] == true) {
        final userData = response['user'] as Map<String, dynamic>;
        final role = _parseRole(userData['role'] as String);
        state = AuthState(
          role: role,
          authEmail: e,
          userName: name,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(kLastActiveKey, DateTime.now().millisecondsSinceEpoch);
        return null;
      } else {
        await FirebaseAuth.instance.currentUser?.delete();
        state = const AuthState();
        return response['message'] as String? ?? 'Registration failed.';
      }
    } on FirebaseAuthException catch (e) {
      state = const AuthState();
      return _firebaseAuthErrorMessage(e);
    } on ApiException catch (e) {
      state = const AuthState();
      return e.message;
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
    await api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kLastActiveKey);
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
  UserRole.vendor => '/vendor/dashboard',
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
