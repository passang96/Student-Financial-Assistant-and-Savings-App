import '../models/auth_result.dart';

class AuthService {
  /// Login authentication logic
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Remove unnecessary spaces
      final cleanEmail = email.trim();
      final cleanPassword = password.trim();

      // Email validation
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

      // Password validation
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

      /*
       TODO:
       Connect Firebase Authentication here
       once Passang completes Firebase setup.

       Example future Firebase code:

       UserCredential credential =
           await FirebaseAuth.instance.signInWithEmailAndPassword(
         email: cleanEmail,
         password: cleanPassword,
       );

       return AuthResult.success(
         message: 'Login successful.',
         userId: credential.user?.uid,
       );
      */

      // Temporary success response for testing.
      return AuthResult.success(
        message: 'Login validation successful. Ready for Firebase connection.',
      );
    } catch (e) {
      return AuthResult.failure(
        'Login failed: $e',
      );
    }
  }

  /// Registration authentication logic
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

      // Name validation
      if (cleanName.isEmpty) {
        return AuthResult.failure(
          'Name is required.',
        );
      }

      // Email validation
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

      // Password validation
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

      // Confirm password
      if (cleanConfirmPassword.isEmpty) {
        return AuthResult.failure(
          'Please confirm your password.',
        );
      }

      if (cleanPassword != cleanConfirmPassword) {
        return AuthResult.failure(
          'Passwords do not match.',
        );
      }

      /*
       TODO:
       Connect Firebase Authentication here
       once Passang completes Firebase setup.

       Example future Firebase code:

       UserCredential credential =
           await FirebaseAuth.instance.createUserWithEmailAndPassword(
         email: cleanEmail,
         password: cleanPassword,
       );

       return AuthResult.success(
         message: 'Registration successful.',
         userId: credential.user?.uid,
       );
      */

      // Temporary success response
      return AuthResult.success(
        message:
            'Registration validation successful. Ready for Firebase connection.',
      );
    } catch (e) {
      return AuthResult.failure(
        'Registration failed: $e',
      );
    }
  }

  /// Checks whether email format is valid
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    );

    return emailRegex.hasMatch(email);
  }
}