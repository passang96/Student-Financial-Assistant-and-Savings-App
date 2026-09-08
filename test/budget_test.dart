import 'package:flutter_test/flutter_test.dart';

import 'package:student_financial_assistant/services/calculation_service.dart';
import 'package:student_financial_assistant/services/notification_service.dart';

void main() {
  group('budget calculations', () {
    test('keeps the exact remaining amount, including an overage', () {
      expect(CalculationService.calculateBudgetRemaining(100, 125), -25);
    });

    test('projects month-end spending from the current daily rate', () {
      final projected = CalculationService.calculateProjectedMonthEndSpending(
        spent: 80,
        now: DateTime(2026, 9, 8),
      );

      expect(projected, closeTo(300, 0.001));
    });

    test('returns zero projection when there is no spending', () {
      expect(
        CalculationService.calculateProjectedMonthEndSpending(
          spent: 0,
          now: DateTime(2026, 9, 8),
        ),
        0,
      );
    });
  });

  group('budget notification thresholds', () {
    test('does not notify below 80 percent', () {
      expect(
        NotificationService.budgetNotificationType(
          budgetAmount: 100,
          spentAmount: 79.99,
        ),
        isNull,
      );
    });

    test('warns from 80 percent through 99 percent', () {
      expect(
        NotificationService.budgetNotificationType(
          budgetAmount: 100,
          spentAmount: 80,
        ),
        'budget_warning',
      );
      expect(
        NotificationService.budgetNotificationType(
          budgetAmount: 100,
          spentAmount: 99.99,
        ),
        'budget_warning',
      );
    });

    test('exceeds at 100 percent or more', () {
      expect(
        NotificationService.budgetNotificationType(
          budgetAmount: 100,
          spentAmount: 100,
        ),
        'budget_exceeded',
      );
    });

    test('rejects invalid budget and spending values safely', () {
      expect(
        NotificationService.budgetNotificationType(
          budgetAmount: 0,
          spentAmount: 1,
        ),
        isNull,
      );
      expect(
        NotificationService.budgetNotificationType(
          budgetAmount: 100,
          spentAmount: -1,
        ),
        isNull,
      );
    });

    test('only projects overspending when projection exceeds budget', () {
      expect(
        NotificationService.shouldNotifyProjectedOverspending(
          projectedAmount: 101,
          budgetAmount: 100,
        ),
        isTrue,
      );
      expect(
        NotificationService.shouldNotifyProjectedOverspending(
          projectedAmount: 100,
          budgetAmount: 100,
        ),
        isFalse,
      );
    });
  });
}
