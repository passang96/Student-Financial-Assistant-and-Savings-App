class SafeSpendingResult {
  final double safeToSpendToday;
  final double availableFunds;
  final double remainingBudget;
  final int daysRemaining;
  final double recentDailyAverage;
  final double safetyBufferPercent;
  final String status;
  final String message;
  final List<String> reasons;

  const SafeSpendingResult({
    required this.safeToSpendToday,
    required this.availableFunds,
    required this.remainingBudget,
    required this.daysRemaining,
    required this.recentDailyAverage,
    required this.safetyBufferPercent,
    required this.status,
    required this.message,
    required this.reasons,
  });
}

class SafeSpendingService {
  SafeSpendingResult calculateSafeSpending({
    required double income,
    required double expenses,
    required double savings,
    required double monthlyBudget,
    required List<double> recentDailyExpenses,
    DateTime? currentDate,
  }) {
    final DateTime now = currentDate ?? DateTime.now();

    final int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;

    final int daysRemaining = totalDaysInMonth - now.day + 1;

    final double netBalance = income - expenses;

    final double availableFunds = netBalance - savings;

    final double remainingBudget = monthlyBudget - expenses;

    double recentDailyAverage = 0;

    if (recentDailyExpenses.isNotEmpty) {
      final double totalRecentSpending = recentDailyExpenses.fold(
        0,
        (sum, value) => sum + value,
      );

      recentDailyAverage = totalRecentSpending / recentDailyExpenses.length;
    }

    const double safetyBufferPercent = 20;

    if (availableFunds <= 0 || remainingBudget <= 0 || daysRemaining <= 0) {
      return SafeSpendingResult(
        safeToSpendToday: 0,
        availableFunds: availableFunds,
        remainingBudget: remainingBudget < 0 ? 0 : remainingBudget,
        daysRemaining: daysRemaining < 0 ? 0 : daysRemaining,
        recentDailyAverage: recentDailyAverage,
        safetyBufferPercent: safetyBufferPercent,
        status: 'Pause Spending',
        message:
            'Your current financial position does not leave room for additional discretionary spending today.',
        reasons: [
          if (availableFunds <= 0)
            'No positive available funds remain after expenses and savings.',
          if (remainingBudget <= 0)
            'Your monthly spending budget has been fully used or exceeded.',
        ],
      );
    }

    final double availableFundsPerDay = availableFunds / daysRemaining;

    final double budgetPerDay = remainingBudget / daysRemaining;

    double baseDailyLimit = availableFundsPerDay < budgetPerDay
        ? availableFundsPerDay
        : budgetPerDay;

    final double safetyBuffer = baseDailyLimit * (safetyBufferPercent / 100);

    double safeToSpendToday = baseDailyLimit - safetyBuffer;

    if (safeToSpendToday < 0) {
      safeToSpendToday = 0;
    }

    final List<String> reasons = [];

    reasons.add(
      'You have \$${availableFunds.toStringAsFixed(2)} available after expenses and savings.',
    );

    reasons.add(
      'You have \$${remainingBudget.toStringAsFixed(2)} remaining in your monthly budget.',
    );

    reasons.add(
      '$daysRemaining day${daysRemaining == 1 ? '' : 's'} remain in the current month.',
    );

    reasons.add(
      'A ${safetyBufferPercent.toStringAsFixed(0)}% safety buffer is kept aside for unexpected spending.',
    );

    String status;
    String message;

    if (recentDailyExpenses.isEmpty) {
      status = 'Getting Started';

      message =
          'Your safe spending estimate is based on your available funds, budget and remaining days. More transaction history will make the comparison more useful.';
    } else if (recentDailyAverage <= safeToSpendToday * 0.80) {
      status = 'On Track';

      message =
          'Your recent daily spending is comfortably below today\'s recommended spending level.';
    } else if (recentDailyAverage <= safeToSpendToday) {
      status = 'Stay Mindful';

      message =
          'Your recent spending is close to your recommended daily amount. Keep an eye on non-essential purchases.';
    } else {
      status = 'Slow Down';

      message =
          'Your recent daily spending is above your current safe spending estimate.';
    }

    if (recentDailyExpenses.isNotEmpty) {
      reasons.add(
        'Your recent average spending is \$${recentDailyAverage.toStringAsFixed(2)} per day.',
      );
    }

    return SafeSpendingResult(
      safeToSpendToday: safeToSpendToday,
      availableFunds: availableFunds,
      remainingBudget: remainingBudget,
      daysRemaining: daysRemaining,
      recentDailyAverage: recentDailyAverage,
      safetyBufferPercent: safetyBufferPercent,
      status: status,
      message: message,
      reasons: reasons,
    );
  }
}
