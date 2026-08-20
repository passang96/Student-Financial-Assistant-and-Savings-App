class FinancialSummary {
  final double income;
  final double expenses;
  final double balance;
  final Map<String, double> categorySpending;
  final String highestCategory;

  FinancialSummary({
    required this.income,
    required this.expenses,
    required this.balance,
    required this.categorySpending,
    required this.highestCategory,
  });
}
