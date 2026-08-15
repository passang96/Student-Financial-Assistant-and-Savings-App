import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/utils/firebase_auth_error_message.dart';

void main() {
  group('FirebaseAuthErrorMessage', () {
    const expectedMessages = <String, String>{
      'wrong-password': 'The password is incorrect. Please try again.',
      'invalid-email': 'Please enter a valid email address.',
      'user-not-found': 'No account was found for that email.',
      'email-already-in-use': 'An account already exists for that email.',
      'weak-password': 'Choose a stronger password with at least 6 characters.',
    };

    for (final entry in expectedMessages.entries) {
      test('maps ${entry.key}', () {
        expect(FirebaseAuthErrorMessage.forCode(entry.key), entry.value);
      });
    }

    test('uses a safe message for an unknown Firebase error', () {
      expect(
        FirebaseAuthErrorMessage.forCode('unexpected-error'),
        'Authentication failed. Please try again.',
      );
    });
  });
}
