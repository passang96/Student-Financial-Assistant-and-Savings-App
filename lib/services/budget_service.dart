import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

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

  CollectionReference<Map<String, dynamic>> get _transactions {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return _firestore.collection('users').doc(uid).collection('transactions');
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

    await checkCurrentMonthBudgetAlerts();
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

    await checkCurrentMonthBudgetAlerts();
  }

  Future<void> saveAllCategoryBudgets(
    Map<String, double> categoryBudgets,
  ) async {
    await monthlyBudgetDocument.set({
      'categoryBudgets': categoryBudgets,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await checkCurrentMonthBudgetAlerts();
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

  Future<void> checkCurrentMonthBudgetAlerts() async {
    if (uid == null) {
      return;
    }

    final budgetSnapshot = await monthlyBudgetDocument.get();

    if (!budgetSnapshot.exists) {
      return;
    }

    final budgetData = budgetSnapshot.data();

    if (budgetData == null) {
      return;
    }

    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1);

    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    final transactionSnapshot = await _transactions
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .get();

    double totalExpenses = 0;

    final Map<String, double> categoryExpenses = {};

    for (final document in transactionSnapshot.docs) {
      final data = document.data();

      final String type = data['type']?.toString().toLowerCase() ?? '';

      if (type != 'expense') {
        continue;
      }

      final double amount = (data['amount'] as num?)?.toDouble() ?? 0;

      if (amount <= 0) {
        continue;
      }

      final String category = data['category']?.toString().trim() ?? 'Other';

      totalExpenses += amount;

      categoryExpenses[category] = (categoryExpenses[category] ?? 0) + amount;
    }

    final double totalBudget =
        (budgetData['totalBudget'] as num?)?.toDouble() ?? 0;

    if (totalBudget > 0) {
      await _notificationService.checkBudget(
        budgetId: 'overall_monthly_budget',
        category: 'overall monthly',
        budgetAmount: totalBudget,
        spentAmount: totalExpenses,
      );
    }

    final rawCategoryBudgets = budgetData['categoryBudgets'];

    if (rawCategoryBudgets is Map) {
      for (final entry in rawCategoryBudgets.entries) {
        final String category = entry.key.toString().trim();

        final dynamic rawLimit = entry.value;

        if (category.isEmpty || rawLimit is! num) {
          continue;
        }

        final double categoryLimit = rawLimit.toDouble();

        if (categoryLimit <= 0) {
          continue;
        }

        final double spentAmount = categoryExpenses[category] ?? 0;

        await _notificationService.checkBudget(
          budgetId: 'category_${_safeBudgetId(category)}',
          category: category,
          budgetAmount: categoryLimit,
          spentAmount: spentAmount,
        );
      }
    }
  }

  String _safeBudgetId(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
