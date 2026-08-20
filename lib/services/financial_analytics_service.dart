import '../models/financial_summary.dart';
import 'transaction_service.dart';

class FinancialAnalyticsService {
  final TransactionService _transactionService = TransactionService();

  Future<FinancialSummary> getSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await _transactionService.getTransactionsOnce(
      startDate: startDate,
      endDate: endDate,
    );

    double income = 0;
    double expenses = 0;

    final Map<String, double> categorySpending = {};

    for (final transaction in transactions) {
      if (transaction.isIncome) {
        income += transaction.amount;
      }

      if (transaction.isExpense) {
        expenses += transaction.amount;

        categorySpending[transaction.category] =
            (categorySpending[transaction.category] ?? 0) + transaction.amount;
      }
    }

    String highestCategory = 'None';

    if (categorySpending.isNotEmpty) {
      highestCategory = categorySpending.entries.reduce((a, b) {
        return a.value >= b.value ? a : b;
      }).key;
    }

    return FinancialSummary(
      income: income,
      expenses: expenses,
      balance: income - expenses,
      categorySpending: categorySpending,
      highestCategory: highestCategory,
    );
  }

  Future<double> getIncome({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final summary = await getSummary(startDate: startDate, endDate: endDate);

    return summary.income;
  }

  Future<double> getExpenses({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final summary = await getSummary(startDate: startDate, endDate: endDate);

    return summary.expenses;
  }

  Future<Map<String, double>> getCategorySpending({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final summary = await getSummary(startDate: startDate, endDate: endDate);

    return summary.categorySpending;
  }

  double percentageChange({required double current, required double previous}) {
    if (previous == 0) {
      if (current == 0) {
        return 0;
      }

      return 100;
    }

    return ((current - previous) / previous) * 100;
  }
}
