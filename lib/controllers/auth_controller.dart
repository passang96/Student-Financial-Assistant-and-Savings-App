import '../models/auth_result.dart';
import '../services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return await _authService.login(email: email, password: password);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    return await _authService.register(
      name: name,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  Future<AuthResult> logout() async {
    return await _authService.logout();
  }

  bool get isLoggedIn {
    return _authService.isLoggedIn;
  }
}
