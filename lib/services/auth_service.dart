import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_result.dart';
import '../models/user_profile.dart';
import '../utils/auth_validator.dart';
import '../utils/firebase_auth_error_message.dart';
import 'user_profile_store.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, UserProfileStore? profileStore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _profileStore = profileStore;

  final FirebaseAuth _firebaseAuth;
  final UserProfileStore? _profileStore;

  UserProfileStore get _resolvedProfileStore =>
      _profileStore ?? FirebaseUserProfileStore();

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    final emailError = AuthValidator.validateEmail(cleanEmail);
    if (emailError != null) {
      return _validationFailure(emailError);
    }

    final passwordError = AuthValidator.validatePassword(password);
    if (passwordError != null) {
      return _validationFailure(passwordError);
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

      return AuthResult.success(message: 'Login successful.', userId: user.uid);
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

    final nameError = AuthValidator.validateName(cleanName);
    if (nameError != null) {
      return _validationFailure(nameError);
    }

    final emailError = AuthValidator.validateEmail(cleanEmail);
    if (emailError != null) {
      return _validationFailure(emailError);
    }

    final passwordError = AuthValidator.validatePassword(password);
    if (passwordError != null) {
      return _validationFailure(passwordError);
    }

    final confirmationError = AuthValidator.validateConfirmPassword(
      password: password,
      confirmPassword: confirmPassword,
    );
    if (confirmationError != null) {
      return _validationFailure(confirmationError);
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
      await _resolvedProfileStore.save(
        UserProfile(
          uid: user.uid,
          displayName: cleanName,
          email: user.email?.trim() ?? cleanEmail,
        ),
      );

      return AuthResult.success(
        message: 'Registration successful.',
        userId: user.uid,
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_firebaseErrorMessage(error));
    } catch (_) {
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> forgotPassword({required String email}) async {
    final cleanEmail = email.trim();

    final emailError = AuthValidator.validateEmail(cleanEmail);
    if (emailError != null) {
      return _validationFailure(emailError);
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

  Future<UserProfile?> loadProfile() async {
    final user = currentUser;
    if (user == null) {
      return null;
    }

    try {
      final storedProfile = await _resolvedProfileStore.load(user.uid);
      if (storedProfile != null) {
        return UserProfile.fromMap(
          uid: user.uid,
          data: storedProfile,
          fallbackUser: user,
        );
      }
    } catch (_) {
      // Firebase Authentication remains a safe fallback if the profile
      // document is temporarily unavailable.
    }

    return UserProfile.fromUser(user);
  }

  Future<AuthResult> updateProfileName({required String name}) async {
    final cleanName = name.trim();
    final nameError = AuthValidator.validateName(cleanName);
    if (nameError != null) {
      return _validationFailure(nameError);
    }

    final user = currentUser;
    if (user == null) {
      return AuthResult.failure(
        'Your session has expired. Please log in again.',
      );
    }

    try {
      await user.updateDisplayName(cleanName);
      await user.reload();
      await _resolvedProfileStore.save(
        UserProfile(
          uid: user.uid,
          displayName: cleanName,
          email: user.email?.trim() ?? '',
        ),
      );
      return AuthResult.success(message: 'Profile updated successfully.');
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_firebaseErrorMessage(error));
    } catch (_) {
      return AuthResult.failure(
        'Your profile could not be updated. Please try again.',
      );
    }
  }

  User? get currentUser => _firebaseAuth.currentUser;
  String? get currentUserId => currentUser?.uid;
  String? get currentUserEmail => currentUser?.email;
  String? get currentUserName => currentUser?.displayName;
  bool get isLoggedIn => currentUser != null;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  Stream<User?> get userChanges => _firebaseAuth.userChanges();

  AuthResult _validationFailure(String message) {
    return AuthResult.failure('$message.');
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    return FirebaseAuthErrorMessage.forCode(error.code);
  }
}
