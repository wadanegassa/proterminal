import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed unused import
import '../../../core/network/firebase_service.dart';
import '../../../core/providers/service_providers.dart';

// Stream-based auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Auth actions notifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(firebaseServiceProvider));
});

class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({this.isLoading = false, this.error});

  AuthState copyWith({bool? isLoading, String? error}) =>
      AuthState(isLoading: isLoading ?? this.isLoading, error: error);

  AuthState clearError() => AuthState(isLoading: isLoading);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseService _service;

  AuthNotifier(this._service) : super(const AuthState());

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _service.createUserProfile(cred.user!.uid, name, email.trim(), phone);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, error: _mapError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  void clearError() {
    state = state.clearError();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
