class GoalProgress {
  static double calculateProgress({
    required double currentAmount,
    required double targetAmount,
  }) {
    if (targetAmount <= 0) {
      return 0;
    }

    final progress = (currentAmount / targetAmount) * 100;
    return progress.clamp(0.0, 100.0).toDouble();
  }

  static double calculateRemaining({
    required double currentAmount,
    required double targetAmount,
  }) {
    final remaining = targetAmount - currentAmount;
    return remaining < 0 ? 0.0 : remaining;
  }

  static bool isAchieved({
    required double currentAmount,
    required double targetAmount,
  }) {
    return targetAmount > 0 && currentAmount >= targetAmount;
  }

  static void validate({required String name, required double targetAmount}) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Goal name cannot be empty');
    }

    if (!targetAmount.isFinite || targetAmount <= 0) {
      throw ArgumentError('Target amount must be greater than 0');
    }
  }
}
