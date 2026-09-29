import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/services/firestore_service.dart';

const _projectId = 'demo-student-financial-assistant';
const _emulatorOptions = FirebaseOptions(
  apiKey: 'fake-api-key',
  appId: '1:1234567890:web:integration-test',
  messagingSenderId: '1234567890',
  projectId: _projectId,
);

void main() {
  final firestoreHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final authHost = Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'];
  final missingEmulators = firestoreHost == null || authHost == null;

  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'creates, reads, updates, and deletes a transaction in Firestore',
    () async {
      final firestoreAddress = _parseAddress(firestoreHost!);
      final authAddress = _parseAddress(authHost!);
      final app = await Firebase.initializeApp(options: _emulatorOptions);
      final firestore = FirebaseFirestore.instanceFor(app: app);
      final auth = FirebaseAuth.instanceFor(app: app);
      firestore.useFirestoreEmulator(
        firestoreAddress.host,
        firestoreAddress.port,
      );
      await auth.useAuthEmulator(authAddress.host, authAddress.port);
      await auth.signInAnonymously();

      final service = FirestoreService();
      final date = DateTime(2026, 9, 1);
      await service.addTransaction(
        type: 'Expense',
        amount: 42,
        category: 'Food',
        date: date,
      );

      final created = await service.transactions.get();
      expect(created.docs, hasLength(1));
      final transactionId = created.docs.single.id;
      expect(created.docs.single.data()['amount'], 42);

      await service.updateTransaction(
        transactionId: transactionId,
        type: 'Income',
        amount: 75,
        category: 'Work',
        date: date,
      );

      final updated = await service.transactions.doc(transactionId).get();
      expect(updated.data()?['amount'], 75);
      expect(updated.data()?['type'], 'Income');
      expect(updated.data()?['category'], 'Work');

      await service.deleteTransaction(transactionId);
      final deleted = await service.transactions.doc(transactionId).get();
      expect(deleted.exists, isFalse);

      await auth.signOut();
      await app.delete();
    },
    skip: missingEmulators
        ? 'Set FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST to run.'
        : false,
  );
}

({String host, int port}) _parseAddress(String address) {
  final separator = address.lastIndexOf(':');
  if (separator < 0) {
    throw FormatException('Expected host:port, got "$address".');
  }

  return (
    host: address.substring(0, separator),
    port: int.parse(address.substring(separator + 1)),
  );
}
