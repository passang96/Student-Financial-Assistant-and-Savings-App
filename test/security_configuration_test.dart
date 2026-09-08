import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/services/transaction_import_service.dart';
import 'package:student_financial_assistant/services/user_profile_store.dart';

void main() {
  test('all persisted user data paths contain the authenticated UID', () {
    expect(FirebaseUserProfileStore.documentPath('auth-uid'), 'users/auth-uid');
    expect(
      TransactionImportService.collectionPath('auth-uid'),
      'users/auth-uid/transactions',
    );
  });

  test('Firestore rules require the signed-in user to own the UID path', () {
    final rules = File('firestore.rules').readAsStringSync();

    expect(rules, contains('request.auth != null'));
    expect(rules, contains('request.auth.uid == userId'));
    expect(rules, contains('match /users/{userId}'));
    expect(rules, contains('match /{userDocument=**}'));
    expect(rules, isNot(contains('allow read, write: if true')));
  });

  test('Firebase config points deployments at the owner-only rules', () {
    final config = File('firebase.json').readAsStringSync();
    expect(config, contains('"rules": "firestore.rules"'));
  });
}
