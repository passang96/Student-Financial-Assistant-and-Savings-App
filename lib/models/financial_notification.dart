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

  static const demoNotifications = <FinancialNotification>[
    FinancialNotification(
      id: 'transport-exceeded',
      type: FinancialNotificationType.budgetExceeded,
      title: 'Transport budget exceeded',
      message:
          'You have spent \$135 this month, which is \$15 over your limit.',
      timeLabel: '10 min ago',
      isToday: true,
      progress: 1,
      amountLabel: '\$135 of \$120 spent',
    ),
    FinancialNotification(
      id: 'dining-warning',
      type: FinancialNotificationType.budgetWarning,
      title: 'Dining budget is nearly full',
      message: 'You have used 82% of your dining budget for this month.',
      timeLabel: '2 hours ago',
      isToday: true,
      progress: 0.82,
      amountLabel: '\$180 of \$220 spent',
    ),
    FinancialNotification(
      id: 'emergency-fund-achieved',
      type: FinancialNotificationType.goalAchieved,
      title: 'Emergency fund achieved!',
      message: 'Amazing work - you reached your \$1,000 savings goal.',
      timeLabel: 'Yesterday',
      isToday: false,
      progress: 1,
      amountLabel: '\$1,000 of \$1,000 saved',
    ),
    FinancialNotification(
      id: 'laptop-progress',
      type: FinancialNotificationType.goalProgress,
      title: 'Laptop fund is halfway there',
      message: 'You are 50% of the way to your goal. Keep it going!',
      timeLabel: '3 days ago',
      isToday: false,
      isRead: true,
      progress: 0.5,
      amountLabel: '\$750 of \$1,500 saved',
    ),
  ];
}
