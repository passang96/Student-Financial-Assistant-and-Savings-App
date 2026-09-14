class BudgetStatus {
  final bool hasBudget;
  final double budgetAmount;
  final double spent;
  final double remaining;
  final double percentUsed;

  const BudgetStatus({
    required this.hasBudget,
    required this.budgetAmount,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
  });
}
