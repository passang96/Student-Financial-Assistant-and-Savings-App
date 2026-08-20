class AuthResult {
  final bool isSuccess;
  final String message;
  final String? userId;

  const AuthResult({
    required this.isSuccess,
    required this.message,
    this.userId,
  });

  factory AuthResult.success({
    required String message,
    String? userId,
  }) {
    return AuthResult(
      isSuccess: true,
      message: message,
      userId: userId,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult(
      isSuccess: false,
      message: message,
    );
  }
}
