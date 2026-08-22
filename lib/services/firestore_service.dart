import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'budget_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BudgetService _budgetService = BudgetService();

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get transactions {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return _firestore.collection('users').doc(uid).collection('transactions');
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    required DateTime date,
    String notes = '',
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await transactions.add({
      'type': type,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'notes': notes.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _refreshBudgetAlertsSafely();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getTransactions() {
    return transactions.orderBy('date', descending: true).snapshots();
  }

  Future<void> updateTransaction({
    required String transactionId,
    required String type,
    required double amount,
    required String category,
    required DateTime date,
    String notes = '',
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await transactions.doc(transactionId).update({
      'type': type,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'notes': notes.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _refreshBudgetAlertsSafely();
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await transactions.doc(transactionId).delete();

    await _refreshBudgetAlertsSafely();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCurrentMonthTransactions() {
    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1);

    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    return transactions
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .orderBy('date', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPreviousMonthTransactions() {
    final now = DateTime.now();

    final startOfPreviousMonth = DateTime(now.year, now.month - 1, 1);

    final startOfCurrentMonth = DateTime(now.year, now.month, 1);

    return transactions
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfPreviousMonth),
        )
        .where('date', isLessThan: Timestamp.fromDate(startOfCurrentMonth))
        .orderBy('date', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getTransactionsByType(
    String type,
  ) {
    return transactions
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getTransactionsByCategory(
    String category,
  ) {
    return transactions
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> _refreshBudgetAlertsSafely() async {
    try {
      await _budgetService.checkCurrentMonthBudgetAlerts();
    } catch (_) {
      // A transaction should remain successfully saved even
      // if a budget notification check temporarily fails.
    }
  }
}
