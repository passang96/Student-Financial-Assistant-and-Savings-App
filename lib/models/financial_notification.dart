enum FinancialNotificationType {
  budgetWarning,
  budgetExceeded,
  goalProgress,
  goalAchieved,
}

class FinancialNotification {
  const FinancialNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.isToday,
    this.isRead = false,
    this.progress,
    this.amountLabel,
  });

  final String id;
  final FinancialNotificationType type;
  final String title;
  final String message;
  final String timeLabel;
  final bool isToday;
  final bool isRead;
  final double? progress;
  final String? amountLabel;

  FinancialNotification copyWith({bool? isRead}) {
    return FinancialNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      timeLabel: timeLabel,
      isToday: isToday,
      isRead: isRead ?? this.isRead,
      progress: progress,
      amountLabel: amountLabel,
    );
  }
}
