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
    final remaining = budget - spent;

    return remaining < 0 ? 0 : remaining;
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
