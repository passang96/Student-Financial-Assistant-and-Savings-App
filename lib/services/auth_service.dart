import '../models/auth_result.dart';

abstract class AuthService {
  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> logout();
}