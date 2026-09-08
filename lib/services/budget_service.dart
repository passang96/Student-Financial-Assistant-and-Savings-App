import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import 'calculation_service.dart';
import 'notification_service.dart';
import 'transaction_service.dart';

class BudgetStatus {
  final double budget;
  final double spent;
  final double remaining;
  final double projectedMonthEnd;

  const BudgetStatus({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.projectedMonthEnd,
  });

  double get percentage => budget <= 0 ? 0 : spent / budget * 100;
}

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TransactionService _transactionService = TransactionService();
  final NotificationService _notificationService = NotificationService();

  String get userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get budgets =>
      _firestore.collection('users').doc(userId).collection('budgets');

  static String monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  Future<void> saveMonthlyBudget({
    required DateTime month,
    required double overallAmount,
    Map<String, double> categoryBudgets = const {},
  }) async {
    _validateAmount(overallAmount, 'Overall budget');
    for (final entry in categoryBudgets.entries) {
      _validateAmount(entry.value, 'Budget for ${entry.key}');
    }

    final key = monthKey(month);
    await budgets.doc(key).set({
      'month': key,
      'overallAmount': overallAmount,
      'categoryBudgets': categoryBudgets,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<BudgetModel?> getMonthlyBudget(DateTime month) async {
    final snapshot = await budgets.doc(monthKey(month)).get();
    final data = snapshot.data();
    return snapshot.exists && data != null
        ? BudgetModel.fromMap(data, snapshot.id)
        : null;
  }

  Future<BudgetStatus> getOverallStatus({DateTime? date}) async {
    final current = date ?? DateTime.now();
    final budget = await getMonthlyBudget(current);
    final transactions = await _monthTransactions(current);
    final spent = _expenseTotal(transactions);
    final amount = budget?.overallAmount ?? 0;
    return _status(amount, spent, current);
  }

  Future<Map<String, BudgetStatus>> getCategoryStatuses({
    DateTime? date,
  }) async {
    final current = date ?? DateTime.now();
    final budget = await getMonthlyBudget(current);
    if (budget == null) {
      return {};
    }

    final transactions = await _monthTransactions(current);
    final result = <String, BudgetStatus>{};
    for (final entry in budget.categoryBudgets.entries) {
      final spent = _expenseTotal(
        transactions.where((transaction) => transaction.category == entry.key),
      );
      result[entry.key] = _status(entry.value, spent, current);
    }
    return result;
  }

  Future<void> checkCurrentMonth({DateTime? date}) async {
    final current = date ?? DateTime.now();
    final budget = await getMonthlyBudget(current);
    if (budget == null) {
      return;
    }

    final transactions = await _monthTransactions(current);
    await _notify(
      budgetId: budget.id,
      category: 'overall',
      status: _status(
        budget.overallAmount,
        _expenseTotal(transactions),
        current,
      ),
    );

    for (final entry in budget.categoryBudgets.entries) {
      await _notify(
        budgetId: '${budget.id}_${entry.key}',
        category: entry.key,
        status: _status(
          entry.value,
          _expenseTotal(
            transactions.where(
              (transaction) => transaction.category == entry.key,
            ),
          ),
          current,
        ),
      );
    }
  }

  Future<List<TransactionModel>> _monthTransactions(DateTime date) {
    return _transactionService.getTransactionsOnce(
      startDate: DateTime(date.year, date.month, 1),
      endDate: DateTime(date.year, date.month + 1, 0),
    );
  }

  Future<void> _notify({
    required String budgetId,
    required String category,
    required BudgetStatus status,
  }) async {
    if (status.budget <= 0) {
      return;
    }
    await _notificationService.checkBudget(
      budgetId: budgetId,
      category: category,
      budgetAmount: status.budget,
      spentAmount: status.spent,
    );
    await _notificationService.projectedOverspending(
      category: category,
      projectedAmount: status.projectedMonthEnd,
      budgetAmount: status.budget,
    );
  }

  BudgetStatus _status(double budget, double spent, DateTime date) {
    return BudgetStatus(
      budget: budget,
      spent: spent,
      remaining: CalculationService.calculateBudgetRemaining(budget, spent),
      projectedMonthEnd: CalculationService.calculateProjectedMonthEndSpending(
        spent: spent,
        now: date,
      ),
    );
  }

  double _expenseTotal(Iterable<TransactionModel> transactions) {
    return transactions
        .where((transaction) => transaction.isExpense)
        .fold(0.0, (total, transaction) => total + transaction.amount);
  }

  void _validateAmount(double amount, String label) {
    if (amount <= 0) {
      throw ArgumentError('$label must be greater than 0');
    }
  }
}
