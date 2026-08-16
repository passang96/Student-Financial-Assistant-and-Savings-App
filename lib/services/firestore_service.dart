import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get currently logged-in user's Firebase UID
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // Reference to current user's transactions
  CollectionReference<Map<String, dynamic>> get transactions {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return _firestore.collection('users').doc(uid).collection('transactions');
  }

  // CREATE / ADD TRANSACTION
  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await transactions.add({
      'type': type,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // READ ALL TRANSACTIONS
  Stream<QuerySnapshot<Map<String, dynamic>>> getTransactions() {
    return transactions.orderBy('date', descending: true).snapshots();
  }

  // UPDATE / EDIT TRANSACTION
  Future<void> updateTransaction({
    required String transactionId,
    required String type,
    required double amount,
    required String category,
    required DateTime date,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await transactions.doc(transactionId).update({
      'type': type,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // DELETE TRANSACTION
  Future<void> deleteTransaction(String transactionId) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await transactions.doc(transactionId).delete();
  }

  // GET CURRENT MONTH TRANSACTIONS
  Stream<QuerySnapshot<Map<String, dynamic>>> getCurrentMonthTransactions() {
    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1);

    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    return transactions
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .snapshots();
  }

  // GET PREVIOUS MONTH TRANSACTIONS
  Stream<QuerySnapshot<Map<String, dynamic>>> getPreviousMonthTransactions() {
    final now = DateTime.now();

    // Start of previous month
    final startOfPreviousMonth = DateTime(now.year, now.month - 1, 1);

    // Start of current month
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);

    return transactions
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfPreviousMonth),
        )
        .where('date', isLessThan: Timestamp.fromDate(startOfCurrentMonth))
        .snapshots();
  }

  // FILTER TRANSACTIONS BY TYPE

  Stream<QuerySnapshot<Map<String, dynamic>>> getTransactionsByType(
    String type,
  ) {
    return transactions
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // FILTER TRANSACTIONS BY CATEGORY
  Stream<QuerySnapshot<Map<String, dynamic>>> getTransactionsByCategory(
    String category,
  ) {
    return transactions
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots();
  }
}
