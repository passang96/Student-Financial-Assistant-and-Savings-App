import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get transactions {
    return _firestore.collection('transactions');
  }

  CollectionReference<Map<String, dynamic>> get csvImports {
    return _firestore.collection('csvImports');
  }

  // SAVE MANUAL TRANSACTION

  Future<void> addManualTransaction(TransactionModel transaction) async {
    final doc = transactions.doc();

    final newTransaction = transaction.copyWith(
      id: doc.id,
      userId: userId,
      source: 'manual',
    );

    await doc.set(newTransaction.toMap());
  }

  // CHECK IF CSV HAS ALREADY BEEN IMPORTED

  Future<bool> isDuplicateImport(String importId) async {
    final documentId = '${userId}_$importId';

    final document = await csvImports.doc(documentId).get();

    return document.exists;
  }

  // BULK SAVE CSV TRANSACTIONS

  Future<void> saveCsvTransactions({
    required List<TransactionModel> transactionsToImport,
    required String importId,
    String? fileName,
  }) async {
    if (transactionsToImport.isEmpty) {
      throw Exception('No transactions to import');
    }

    final duplicate = await isDuplicateImport(importId);

    if (duplicate) {
      throw Exception('This CSV file has already been imported.');
    }

    final batch = _firestore.batch();

    for (final transaction in transactionsToImport) {
      final doc = transactions.doc();

      final csvTransaction = transaction.copyWith(
        id: doc.id,
        userId: userId,

        // IMPORTANT
        source: 'csv',

        importId: importId,
      );

      batch.set(doc, csvTransaction.toMap());
    }

    // Save record of CSV import
    final importDocument = csvImports.doc('${userId}_$importId');

    batch.set(importDocument, {
      'userId': userId,
      'importId': importId,
      'fileName': fileName ?? '',
      'transactionCount': transactionsToImport.length,
      'importedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // GET ALL USER TRANSACTIONS

  Stream<List<TransactionModel>> getAllTransactions() {
    return transactions
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(TransactionModel.fromDocument).toList(),
        );
  }

  // DATE RANGE STREAM

  Stream<List<TransactionModel>> getTransactionsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    return transactions
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(TransactionModel.fromDocument).toList(),
        );
  }

  // GET DATE RANGE ONCE
  // Used for reports / calculations

  Future<List<TransactionModel>> getTransactionsOnce({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    final snapshot = await transactions
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map(TransactionModel.fromDocument).toList();
  }

  // DELETE TRANSACTION

  Future<void> deleteTransaction(String transactionId) async {
    await transactions.doc(transactionId).delete();
  }
}
