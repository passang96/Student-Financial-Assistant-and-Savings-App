import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/utils/auth_validator.dart';

void main() {
  group('AuthValidator', () {
    test('accepts valid names, emails, and passwords', () {
      expect(AuthValidator.validateName('Pema Dorji'), isNull);
      expect(AuthValidator.validateEmail('pema@example.com'), isNull);
      expect(AuthValidator.validatePassword('secure123'), isNull);
      expect(
        AuthValidator.validateConfirmPassword(
          password: 'secure123',
          confirmPassword: 'secure123',
        ),
        isNull,
      );
    });

    test('rejects malformed or missing registration details', () {
      expect(AuthValidator.validateName(''), 'Name is required');
      expect(
        AuthValidator.validateEmail('not-an-email'),
        'Enter a valid email address',
      );
      expect(
        AuthValidator.validatePassword('12345'),
        'Password must be at least 6 characters',
      );
      expect(
        AuthValidator.validateConfirmPassword(
          password: 'secure123',
          confirmPassword: 'different',
        ),
        'Passwords do not match',
      );
    });
  });
}
