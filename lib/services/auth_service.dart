import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_result.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final cleanEmail = email.trim();
      final cleanPassword = password.trim();

      if (cleanEmail.isEmpty) {
        return AuthResult.failure('Email is required.');
      }

      if (!_isValidEmail(cleanEmail)) {
        return AuthResult.failure('Please enter a valid email address.');
      }

      if (cleanPassword.isEmpty) {
        return AuthResult.failure('Password is required.');
      }

      if (cleanPassword.length < 6) {
        return AuthResult.failure('Password must be at least 6 characters.');
      }

      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPassword,
          );

      return AuthResult.success(
        message: 'Login successful.',
        userId: credential.user?.uid,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_firebaseErrorMessage(e));
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
    try {
      final cleanName = name.trim();
      final cleanEmail = email.trim();
      final cleanPassword = password.trim();
      final cleanConfirmPassword = confirmPassword.trim();

      if (cleanName.isEmpty) {
        return AuthResult.failure('Name is required.');
      }

      if (cleanEmail.isEmpty) {
        return AuthResult.failure('Email is required.');
      }

      if (!_isValidEmail(cleanEmail)) {
        return AuthResult.failure('Please enter a valid email address.');
      }

      if (cleanPassword.isEmpty) {
        return AuthResult.failure('Password is required.');
      }

      if (cleanPassword.length < 6) {
        return AuthResult.failure('Password must be at least 6 characters.');
      }

      if (cleanConfirmPassword.isEmpty) {
        return AuthResult.failure('Please confirm your password.');
      }

      if (cleanPassword != cleanConfirmPassword) {
        return AuthResult.failure('Passwords do not match.');
      }

      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPassword,
          );

      await credential.user?.updateDisplayName(cleanName);

      return AuthResult.success(
        message: 'Registration successful.',
        userId: credential.user?.uid,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_firebaseErrorMessage(e));
    } catch (_) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> sendPasswordResetEmail({required String email}) async {
    try {
      final cleanEmail = email.trim();

      if (cleanEmail.isEmpty) {
        return AuthResult.failure('Please enter your email address.');
      }

      if (!_isValidEmail(cleanEmail)) {
        return AuthResult.failure('Please enter a valid email address.');
      }

      await _firebaseAuth.sendPasswordResetEmail(email: cleanEmail);

      return AuthResult.success(
        message:
            'Password reset email sent. Please check your inbox and spam folder.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_firebaseErrorMessage(e));
    } catch (_) {
      return AuthResult.failure(
        'Unable to send password reset email. Please try again.',
      );
    }
  }

  Future<AuthResult> logout() async {
    try {
      await _firebaseAuth.signOut();

      return AuthResult.success(message: 'Logged out successfully.');
    } catch (_) {
      return AuthResult.failure('Unable to logout.');
    }
  }

  User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  bool get isLoggedIn {
    return _firebaseAuth.currentUser != null;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');

    return emailRegex.hasMatch(email);
  }

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'Password is too weak.';

      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
