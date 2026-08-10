import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_result.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // LOGIN
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
        return AuthResult.failure(
          'Please enter a valid email address.',
        );
      }

      if (cleanPassword.isEmpty) {
        return AuthResult.failure(
          'Password is required.',
        );
      }

      if (cleanPassword.length < 6) {
        return AuthResult.failure(
          'Password must be at least 6 characters.',
        );
      }

      final UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      return AuthResult.success(
        message: 'Login successful.',
        userId: credential.user?.uid,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getFirebaseErrorMessage(e),
      );
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred.',
      );
    }
  }

  // REGISTER
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
      final cleanConfirmPassword =
          confirmPassword.trim();

      if (cleanName.isEmpty) {
        return AuthResult.failure(
          'Name is required.',
        );
      }

      if (cleanEmail.isEmpty) {
        return AuthResult.failure(
          'Email is required.',
        );
      }

      if (!_isValidEmail(cleanEmail)) {
        return AuthResult.failure(
          'Please enter a valid email address.',
        );
      }

      if (cleanPassword.isEmpty) {
        return AuthResult.failure(
          'Password is required.',
        );
      }

      if (cleanPassword.length < 6) {
        return AuthResult.failure(
          'Password must be at least 6 characters.',
        );
      }

      if (cleanConfirmPassword.isEmpty) {
        return AuthResult.failure(
          'Please confirm your password.',
        );
      }

      if (cleanPassword !=
          cleanConfirmPassword) {
        return AuthResult.failure(
          'Passwords do not match.',
        );
      }

      final UserCredential credential =
          await _firebaseAuth
              .createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      await credential.user
          ?.updateDisplayName(cleanName);

      return AuthResult.success(
        message: 'Registration successful.',
        userId: credential.user?.uid,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(
        _getFirebaseErrorMessage(e),
      );
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred.',
      );
    }
  }

  // LOGOUT
  Future<AuthResult> logout() async {
    try {
      await _firebaseAuth.signOut();

      return AuthResult.success(
        message: 'Logout successful.',
      );
    } catch (e) {
      return AuthResult.failure(
        'Unable to logout.',
      );
    }
  }

  // CHECK CURRENT USER
  User? get currentUser =>
      _firebaseAuth.currentUser;

  // CHECK LOGIN STATUS
  bool get isLoggedIn =>
      _firebaseAuth.currentUser != null;

  // EMAIL VALIDATION
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    );

    return emailRegex.hasMatch(email);
  }

  // FIREBASE ERROR HANDLING
  String _getFirebaseErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is invalid.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
        return 'No account was found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';

      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
        return 'The password is too weak.';

      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Please check your internet connection.';

      default:
        return e.message ??
            'Authentication failed.';
    }
  }
}