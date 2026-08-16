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
