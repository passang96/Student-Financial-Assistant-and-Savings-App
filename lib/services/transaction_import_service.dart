import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/imported_transaction.dart';
import 'budget_service.dart';
import 'import_id_service.dart';

abstract interface class ImportedTransactionWriter {
  Future<void> importTransactions(
    List<ImportedTransaction> transactions, {
    String? fileName,
  });
}

class TransactionImportService implements ImportedTransactionWriter {
  TransactionImportService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    BudgetService? budgetService,
    ImportIdService? importIdService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _budgetService = budgetService ?? BudgetService(),
       _importIdService = importIdService ?? const ImportIdService();

  static const int _writesPerBatch = 450;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final BudgetService _budgetService;
  final ImportIdService _importIdService;

  @override
  Future<void> importTransactions(
    List<ImportedTransaction> transactions, {
    String? fileName,
  }) async {
    if (transactions.isEmpty) {
      return;
    }

    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('You must be logged in to import transactions.');
    }

    final transactionCollection = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    final csvImportCollection = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('csvImports');

    String? importId;

    // Duplicate protection is used when the CSV filename is available.
    if (fileName != null && fileName.trim().isNotEmpty) {
      final totalAmount = transactions.fold<double>(
        0,
        (total, transaction) => total + transaction.amount,
      );

      importId = _importIdService.generateImportId(
        fileName: fileName,
        transactionCount: transactions.length,
        totalAmount: totalAmount,
      );

      final existingImport = await csvImportCollection.doc(importId).get();

      if (existingImport.exists) {
        throw StateError(
          'This CSV file appears to have already been imported.',
        );
      }
    }

    for (var start = 0; start < transactions.length; start += _writesPerBatch) {
      final end = (start + _writesPerBatch).clamp(0, transactions.length);

      final batch = _firestore.batch();

      for (final transaction in transactions.sublist(start, end)) {
        final timestamp = FieldValue.serverTimestamp();

        batch.set(transactionCollection.doc(), {
          'description': transaction.description,

          // Transaction History and Dashboard use
          // `notes` for the visible transaction description.
          'notes': transaction.description,

          'amount': transaction.amount,
          'type': transaction.type.firestoreValue,
          'category': transaction.category,
          'date': Timestamp.fromDate(transaction.date),

          // Marks the transaction as having been
          // imported from an external CSV file.
          'source': 'csv',
          'sourceRow': transaction.sourceRow,

          // Allows imported transactions to be associated
          // with the CSV import record.
          'importId': ?importId,

          'createdAt': timestamp,
          'updatedAt': timestamp,
        });
      }

      await batch.commit();
    }

    // Save a record of the completed CSV import.
    //
    // We only create this record after all transaction batches
    // have been successfully committed.
    if (importId != null) {
      await csvImportCollection.doc(importId).set({
        'fileName': fileName,
        'transactionCount': transactions.length,
        'importedAt': FieldValue.serverTimestamp(),
        'importId': importId,
      });
    }

    // CSV imports write directly to Firestore instead of
    // FirestoreService.addTransaction(), so refresh budget
    // alerts once after the complete import has finished.
    try {
      await _budgetService.checkCurrentMonthBudgetAlerts();
    } catch (_) {
      // The imported transactions have already been saved
      // successfully. A temporary notification failure should
      // not make the whole CSV import appear unsuccessful.
    }
  }
}
