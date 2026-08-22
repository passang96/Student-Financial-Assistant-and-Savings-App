import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/imported_transaction.dart';

abstract interface class ImportedTransactionWriter {
  Future<void> importTransactions(List<ImportedTransaction> transactions);
}

class TransactionImportService implements ImportedTransactionWriter {
  TransactionImportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const int _writesPerBatch = 450;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  @override
  Future<void> importTransactions(
    List<ImportedTransaction> transactions,
  ) async {
    if (transactions.isEmpty) {
      return;
    }

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('You must be logged in to import transactions.');
    }

    final collection = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    for (var start = 0; start < transactions.length; start += _writesPerBatch) {
      final end = (start + _writesPerBatch).clamp(0, transactions.length);
      final batch = _firestore.batch();

      for (final transaction in transactions.sublist(start, end)) {
        final timestamp = FieldValue.serverTimestamp();
        batch.set(collection.doc(), {
          'description': transaction.description,
          // The integrated transaction screens use `notes` for the display
          // text. Keep `description` as well so the import data remains
          // self-describing and compatible with both models.
          'notes': transaction.description,
          'amount': transaction.amount,
          'type': transaction.type.firestoreValue,
          'category': transaction.category,
          'date': Timestamp.fromDate(transaction.date),
          'source': 'csv',
          'sourceRow': transaction.sourceRow,
          'createdAt': timestamp,
          'updatedAt': timestamp,
        });
      }

      await batch.commit();
    }
  }
}
