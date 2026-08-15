import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_result.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      return AuthResult.failure('Email is required.');
    }
    if (!_isValidEmail(cleanEmail)) {
      return AuthResult.failure('Please enter a valid email address.');
    }
    if (password.isEmpty) {
      return AuthResult.failure('Password is required.');
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = credential.user;

      if (user == null) {
        return AuthResult.failure(
          'Login completed without a user account. Please try again.',
        );
      }

      return AuthResult.success(
        message: 'Login successful.',
        userId: user.uid,
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_firebaseErrorMessage(error));
    } catch (_) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      return AuthResult.failure('Name is required.');
    }
    if (cleanName.length < 2) {
      return AuthResult.failure('Name must be at least 2 characters.');
    }
    if (cleanEmail.isEmpty) {
      return AuthResult.failure('Email is required.');
    }
    if (!_isValidEmail(cleanEmail)) {
      return AuthResult.failure('Please enter a valid email address.');
    }
    if (password.isEmpty) {
      return AuthResult.failure('Password is required.');
    }
    if (password.length < 6) {
      return AuthResult.failure('Password must be at least 6 characters.');
    }
    if (confirmPassword.isEmpty) {
      return AuthResult.failure('Please confirm your password.');
    }
    if (password != confirmPassword) {
      return AuthResult.failure('Passwords do not match.');
    }

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final user = credential.user;

      if (user == null) {
        return AuthResult.failure(
          'Registration completed without a user account. Please try again.',
        );
      }

      await user.updateDisplayName(cleanName);
      await user.reload();

      return AuthResult.success(
        message: 'Registration successful.',
        userId: _firebaseAuth.currentUser?.uid ?? user.uid,
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_firebaseErrorMessage(error));
    } catch (_) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> forgotPassword({required String email}) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      return AuthResult.failure('Email is required.');
    }
    if (!_isValidEmail(cleanEmail)) {
      return AuthResult.failure('Please enter a valid email address.');
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: cleanEmail);
      return AuthResult.success(
        message: 'If an account exists for that email, a reset link was sent.',
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_firebaseErrorMessage(error));
    } catch (_) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> logout() async {
    try {
      await _firebaseAuth.signOut();
      return AuthResult.success(message: 'Logged out successfully.');
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_firebaseErrorMessage(error));
    } catch (_) {
      return AuthResult.failure('Unable to log out. Please try again.');
    }
  }

  User? get currentUser => _firebaseAuth.currentUser;
  String? get currentUserId => currentUser?.uid;
  String? get currentUserEmail => currentUser?.email;
  String? get currentUserName => currentUser?.displayName;
  bool get isLoggedIn => currentUser != null;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(email);
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account was found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email and password authentication is not enabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'invalid-api-key':
      case 'app-not-authorized':
        return 'Firebase authentication is not configured correctly.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
