class FirebaseAuthErrorMessage {
  FirebaseAuthErrorMessage._();

  static String forCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account was found for that email.';
      case 'wrong-password':
      case 'invalid-password':
        return 'The password is incorrect. Please try again.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
      case 'email-already-exists':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'missing-email':
        return 'Email is required.';
      case 'missing-password':
        return 'Password is required.';
      case 'operation-not-allowed':
        return 'Email and password authentication is not enabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'user-token-expired':
        return 'Your session has expired. Please log in again.';
      case 'requires-recent-login':
        return 'Please log in again before changing your account.';
      case 'invalid-api-key':
      case 'app-not-authorized':
        return 'Firebase authentication is not configured correctly.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
