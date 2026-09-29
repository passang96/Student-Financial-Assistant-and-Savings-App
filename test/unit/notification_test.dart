import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('retains message and notification type', () {
      final notification = NotificationModel(
        userId: 'user-1',
        title: 'Budget warning',
        message: 'You have used 80% of your food budget.',
        type: 'budget_warning',
      );

      expect(notification.message, 'You have used 80% of your food budget.');
      expect(notification.type, 'budget_warning');
    });

    test('defaults to unread and supports read state', () {
      final unread = NotificationModel(
        userId: 'user-1',
        title: 'Goal progress',
        message: 'Halfway there.',
        type: 'goal_progress',
      );
      final read = NotificationModel(
        userId: 'user-1',
        title: 'Goal progress',
        message: 'Halfway there.',
        type: 'goal_progress',
        isRead: true,
      );

      expect(unread.isRead, isFalse);
      expect(read.isRead, isTrue);
    });
  });
}
