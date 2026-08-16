import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get monthlyBudgetDocument {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final now = DateTime.now();

    final String monthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(monthKey);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getCurrentMonthBudget() {
    return monthlyBudgetDocument.snapshots();
  }

  Future<void> saveMonthlyBudget({required double totalBudget}) async {
    if (totalBudget <= 0) {
      throw Exception('Monthly budget must be greater than zero');
    }

    await monthlyBudgetDocument.set({
      'totalBudget': totalBudget,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveCategoryBudget({
    required String category,
    required double limit,
  }) async {
    if (category.trim().isEmpty) {
      throw Exception('Category cannot be empty');
    }

    if (limit < 0) {
      throw Exception('Budget limit cannot be negative');
    }

    await monthlyBudgetDocument.set({
      'categoryBudgets': {category.trim(): limit},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveAllCategoryBudgets(
    Map<String, double> categoryBudgets,
  ) async {
    await monthlyBudgetDocument.set({
      'categoryBudgets': categoryBudgets,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getCurrentMonthBudgetOnce() async {
    final snapshot = await monthlyBudgetDocument.get();

    if (!snapshot.exists) {
      return {};
    }

    return snapshot.data() ?? {};
  }

  Future<void> deleteCurrentMonthBudget() async {
    await monthlyBudgetDocument.delete();
  }
}
