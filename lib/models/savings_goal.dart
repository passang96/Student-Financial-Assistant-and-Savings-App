import 'dart:math' as math;

class SavingsGoal {
  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.targetDate,
    this.savedAmount = 0,
    this.contributions = const [],
    this.icon = '💰',
  });

  final String id;
  final String title;
  final double targetAmount;
  final DateTime targetDate;
  final double savedAmount;
  final List<GoalContribution> contributions;
  final String icon;

  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);

  bool get isAchieved => savedAmount >= targetAmount;

  int get daysRemaining => targetDate.difference(DateTime.now()).inDays;

  double get remainingAmount {
    final double diff = targetAmount - savedAmount;
    return diff < 0 ? 0 : diff;
  }

  /// True when the target date has passed but the goal isn't funded yet.
  /// The recommendation should not be shown in this case since a weekly
  /// or monthly split no longer makes sense.
  bool get isOverdue => !isAchieved && daysRemaining <= 0;

  /// Whether a Recommended Savings Plan can be shown for this goal.
  bool get canShowRecommendation => !isAchieved && !isOverdue;

  /// Suggested amount to save per week to hit the target on time.
  /// Always rounds up so following the plan slightly over-delivers
  /// rather than falling short by a few cents.
  double get recommendedWeeklyAmount {
    if (!canShowRecommendation) {
      return 0;
    }

    final int weeksLeft = math.max(1, (daysRemaining / 7).ceil());

    return (remainingAmount / weeksLeft * 100).ceil() / 100;
  }

  /// Suggested amount to save per month to hit the target on time.
  double get recommendedMonthlyAmount {
    if (!canShowRecommendation) {
      return 0;
    }

    final int monthsLeft = math.max(1, (daysRemaining / 30).ceil());

    return (remainingAmount / monthsLeft * 100).ceil() / 100;
  }

  SavingsGoal copyWith({
    String? title,
    double? targetAmount,
    DateTime? targetDate,
    double? savedAmount,
    List<GoalContribution>? contributions,
    String? icon,
  }) {
    return SavingsGoal(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      savedAmount: savedAmount ?? this.savedAmount,
      contributions: contributions ?? this.contributions,
      icon: icon ?? this.icon,
    );
  }
}

class GoalContribution {
  GoalContribution({required this.amount, required this.date, this.note});

  final double amount;
  final DateTime date;
  final String? note;
}
