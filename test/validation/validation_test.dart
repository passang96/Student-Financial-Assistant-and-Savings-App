import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/models/goal_progress.dart';

void main() {
  group('goal input validation', () {
    test('rejects an empty goal name', () {
      expect(
        () => GoalProgress.validate(name: '  ', targetAmount: 100),
        throwsArgumentError,
      );
    });

    test('rejects zero, negative, and non-finite targets', () {
      for (final amount in [0.0, -1.0, double.nan, double.infinity]) {
        expect(
          () => GoalProgress.validate(
            name: 'Emergency fund',
            targetAmount: amount,
          ),
          throwsArgumentError,
        );
      }
    });

    test('accepts a non-empty name and positive finite target', () {
      expect(
        () => GoalProgress.validate(name: 'Emergency fund', targetAmount: 500),
        returnsNormally,
      );
    });
  });
}
