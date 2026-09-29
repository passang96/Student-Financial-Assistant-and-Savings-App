import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/models/goal_progress.dart';

void main() {
  group('goal progress', () {
    test('calculates progress toward the saving target', () {
      expect(
        GoalProgress.calculateProgress(currentAmount: 25, targetAmount: 100),
        25,
      );
      expect(
        GoalProgress.calculateRemaining(currentAmount: 25, targetAmount: 100),
        75,
      );
    });

    test('caps progress and remaining balance when target is reached', () {
      expect(
        GoalProgress.calculateProgress(currentAmount: 120, targetAmount: 100),
        100,
      );
      expect(
        GoalProgress.calculateRemaining(currentAmount: 120, targetAmount: 100),
        0,
      );
      expect(
        GoalProgress.isAchieved(currentAmount: 120, targetAmount: 100),
        isTrue,
      );
    });
  });
}
