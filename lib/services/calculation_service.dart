class CalculationService {
  // Calculate total balance
  static double calculateBalance(double income, double expenses) {
    return income - expenses;
  }

  // Calculate savings
  static double calculateSavings(double income, double expenses) {
    return income - expenses;
  }

  // Calculate remaining budget
  static double calculateBudgetRemaining(double budget, double spent) {
    return budget - spent;
  }

  static double calculateProjectedMonthEndSpending({
    required double spent,
    required DateTime now,
  }) {
    if (spent <= 0 || now.day <= 0) {
      return 0;
    }

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return spent / now.day * daysInMonth;
  }

  // Calculate savings goal progress percentage
  static double calculateGoalProgress(
    double currentAmount,
    double targetAmount,
  ) {
    if (targetAmount <= 0) {
      return 0;
    }

    double progress = (currentAmount / targetAmount) * 100;

    if (progress > 100) {
      progress = 100;
    }

    return progress;
  }

  // Calculate remaining amount for savings goal
  static double calculateGoalRemaining(
    double currentAmount,
    double targetAmount,
  ) {
    final remaining = targetAmount - currentAmount;

    return remaining < 0 ? 0 : remaining;
  }

  // Checking savings goal is achieved
  static bool isGoalAchieved(double currentAmount, double targetAmount) {
    return currentAmount >= targetAmount;
  }

  // Calculate percentage change from previous month
  static double calculatePercentageChange(
    double currentAmount,
    double previousAmount,
  ) {
    if (previousAmount == 0) {
      if (currentAmount == 0) {
        return 0;
      }

      return 100;
    }

    return ((currentAmount - previousAmount) / previousAmount) * 100;
  }
}
