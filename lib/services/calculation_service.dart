class CalculationService {
  static double calculateBalance(double income, double expenses) {
    return income - expenses;
  }

  static double calculateSavings(double income, double expenses) {
    return income - expenses;
  }

  static double calculateBudgetRemaining(double budget, double spent) {
    return budget - spent;
  }

  static double calculateProjectedMonthEndSpending({
    required double spent,
    required DateTime now,
  }) {
    if (!spent.isFinite || spent <= 0 || now.day <= 0) {
      return 0;
    }

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return (spent / now.day) * daysInMonth;
  }

  static double calculateGoalProgress(
    double currentAmount,
    double targetAmount,
  ) {
    if (targetAmount <= 0) {
      return 0;
    }

    final progress = (currentAmount / targetAmount) * 100;

    return progress.clamp(0.0, 100.0).toDouble();
  }

  static double calculateGoalRemaining(
    double currentAmount,
    double targetAmount,
  ) {
    final remaining = targetAmount - currentAmount;

    return remaining < 0 ? 0.0 : remaining;
  }

  static bool isGoalAchieved(double currentAmount, double targetAmount) {
    return targetAmount > 0 && currentAmount >= targetAmount;
  }

  static double calculatePercentageChange(
    double currentAmount,
    double previousAmount,
  ) {
    if (previousAmount == 0) {
      return currentAmount == 0 ? 0 : 100;
    }

    return ((currentAmount - previousAmount) / previousAmount) * 100;
  }
}
