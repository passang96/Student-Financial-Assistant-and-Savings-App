/// A single savings goal (e.g. "New Laptop", "Emergency Fund").
///
/// This is a plain Dart model for the frontend to work with. Passang will
/// connect this to Firestore in Round 4 — see the TODOs in savings_screen.dart
/// for where the real read/write calls should replace the mock data.
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
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);

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

/// A single deposit toward a goal.
class GoalContribution {
  GoalContribution({required this.amount, required this.date, this.note});

  final double amount;
  final DateTime date;
  final String? note;
}
