import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/imported_transaction.dart';
import 'budget_service.dart';
import 'import_id_service.dart';

class TransactionImportResult {
  const TransactionImportResult({
    required this.selectedCount,
    required this.importedCount,
    required this.duplicateCount,
  });

  final int selectedCount;
  final int importedCount;
  final int duplicateCount;
}

abstract interface class ImportedTransactionWriter {
  Future<TransactionImportResult> importTransactions(
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
  Future<TransactionImportResult> importTransactions(
    List<ImportedTransaction> transactions, {
    String? fileName,
  }) async {
    if (transactions.isEmpty) {
      return const TransactionImportResult(
        selectedCount: 0,
        importedCount: 0,
        duplicateCount: 0,
      );
    }

    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('You must be logged in to import transactions.');
    }

    final userDocument = _firestore.collection('users').doc(user.uid);

    final transactionCollection = userDocument.collection('transactions');

    final csvImportCollection = userDocument.collection('csvImports');

    final transactionEntries = transactions.map((transaction) {
      final transactionId = _importIdService.generateTransactionId(
        date: transaction.date,
        description: transaction.description,
        amount: transaction.amount,
        type: transaction.type.firestoreValue,
      );

      return _TransactionImportEntry(
        transaction: transaction,
        transactionId: transactionId,
      );
    }).toList();

    /*
     * Remove duplicate transactions that occur inside the
     * currently selected CSV data itself.
     */
    final uniqueEntries = <String, _TransactionImportEntry>{};

    for (final entry in transactionEntries) {
      uniqueEntries.putIfAbsent(entry.transactionId, () => entry);
    }

    final duplicateInsideSelection =
        transactionEntries.length - uniqueEntries.length;

    /*
     * Check whether each transaction fingerprint already
     * exists in Firestore.
     */
    final newEntries = <_TransactionImportEntry>[];

    var duplicateInFirestore = 0;

    for (final entry in uniqueEntries.values) {
      final existingDocument = await transactionCollection
          .doc(entry.transactionId)
          .get();

      if (existingDocument.exists) {
        duplicateInFirestore++;
      } else {
        newEntries.add(entry);
      }
    }

    final totalDuplicateCount = duplicateInsideSelection + duplicateInFirestore;

    /*
     * Nothing new needs to be saved.
     *
     * Return a normal result instead of throwing an error,
     * because duplicate detection is an expected outcome.
     */
    if (newEntries.isEmpty) {
      return TransactionImportResult(
        selectedCount: transactions.length,
        importedCount: 0,
        duplicateCount: totalDuplicateCount,
      );
    }

    /*
     * Generate an ID for this import session.
     *
     * Transaction fingerprints handle duplicate prevention.
     * The import ID is only used to group and record this
     * particular CSV import session.
     */
    String? importId;

    if (fileName != null && fileName.trim().isNotEmpty) {
      final totalAmount = newEntries.fold<double>(
        0,
        (total, entry) => total + entry.transaction.amount,
      );

      final importedTransactions = newEntries
          .map((entry) => entry.transaction)
          .toList();

      final earliestDate = _earliestDate(importedTransactions);

      final latestDate = _latestDate(importedTransactions);

      final periodKey = '${_dateKey(earliestDate)}_${_dateKey(latestDate)}';

      importId = _importIdService.generateImportId(
        fileName: fileName,
        transactionCount: newEntries.length,
        totalAmount: totalAmount,
        periodKey: periodKey,
      );
    }

    /*
     * Save only transactions that do not already exist.
     */
    for (var start = 0; start < newEntries.length; start += _writesPerBatch) {
      final end = (start + _writesPerBatch).clamp(0, newEntries.length);

      final batch = _firestore.batch();

      for (final entry in newEntries.sublist(start, end)) {
        final transaction = entry.transaction;

        final documentReference = transactionCollection.doc(
          entry.transactionId,
        );

        final timestamp = FieldValue.serverTimestamp();

        batch.set(documentReference, {
          'description': transaction.description,

          // Transaction History and Dashboard use notes
          // for the visible transaction description.
          'notes': transaction.description,

          'amount': transaction.amount,
          'type': transaction.type.firestoreValue,
          'category': transaction.category,
          'date': Timestamp.fromDate(transaction.date),

          // CSV-specific metadata.
          'source': 'csv',
          'sourceRow': transaction.sourceRow,
          'transactionFingerprint': entry.transactionId,
          'importId': importId,

          'createdAt': timestamp,
          'updatedAt': timestamp,
        });
      }

      await batch.commit();
    }

    /*
     * Save the CSV import-history record.
     */
    if (importId != null) {
      final importedTransactions = newEntries
          .map((entry) => entry.transaction)
          .toList();

      final earliestDate = _earliestDate(importedTransactions);

      final latestDate = _latestDate(importedTransactions);

      await csvImportCollection.doc(importId).set({
        'fileName': fileName,
        'selectedTransactionCount': transactions.length,
        'transactionCount': newEntries.length,
        'duplicateCount': totalDuplicateCount,
        'periodStart': Timestamp.fromDate(earliestDate),
        'periodEnd': Timestamp.fromDate(latestDate),
        'importedAt': FieldValue.serverTimestamp(),
        'importId': importId,
      });
    }

    /*
     * Refresh budget warnings and projected-spending alerts
     * after the transactions have been saved.
     */
    try {
      await _budgetService.checkCurrentMonthBudgetAlerts();
    } catch (_) {
      // Transaction import already succeeded.
      // Notification failure should not mark the CSV import
      // itself as unsuccessful.
    }

    return TransactionImportResult(
      selectedCount: transactions.length,
      importedCount: newEntries.length,
      duplicateCount: totalDuplicateCount,
    );
  }

  DateTime _earliestDate(List<ImportedTransaction> transactions) {
    var earliest = transactions.first.date;

    for (final transaction in transactions.skip(1)) {
      if (transaction.date.isBefore(earliest)) {
        earliest = transaction.date;
      }
    }

    return earliest;
  }

  DateTime _latestDate(List<ImportedTransaction> transactions) {
    var latest = transactions.first.date;

    for (final transaction in transactions.skip(1)) {
      if (transaction.date.isAfter(latest)) {
        latest = transaction.date;
      }
    }

    return latest;
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

class _TransactionImportEntry {
  const _TransactionImportEntry({
    required this.transaction,
    required this.transactionId,
  });

  final ImportedTransaction transaction;
  final String transactionId;
}
