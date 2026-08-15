import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_result.dart';
import '../services/auth_service.dart';

class AuthController {
  AuthController({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) {
    return _authService.login(email: email, password: password);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return _authService.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  Future<AuthResult> forgotPassword({required String email}) {
    return _authService.forgotPassword(email: email);
  }

  Future<AuthResult> logout() => _authService.logout();

  User? get currentUser => _authService.currentUser;
  String? get currentUserId => _authService.currentUserId;
  String? get currentUserEmail => _authService.currentUserEmail;
  String? get currentUserName => _authService.currentUserName;
  bool get isLoggedIn => _authService.isLoggedIn;
  Stream<User?> get authStateChanges => _authService.authStateChanges;
  Stream<User?> get userChanges => _authService.userChanges;
}
