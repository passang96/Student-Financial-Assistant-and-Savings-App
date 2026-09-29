import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/models/transaction_model.dart';

void main() {
  group('TransactionModel', () {
    final transaction = TransactionModel(
      userId: 'user-1',
      description: 'Part-time work',
      amount: 125.50,
      type: 'Income',
      category: 'Salary',
      date: DateTime(2026, 9, 1),
    );

    test('retains transaction amount and category', () {
      expect(transaction.amount, 125.50);
      expect(transaction.category, 'Salary');
    });

    test('recognizes income and expense types case-insensitively', () {
      expect(transaction.isIncome, isTrue);
      expect(transaction.isExpense, isFalse);

      final expense = transaction.copyWith(type: 'eXpEnSe');
      expect(expense.isExpense, isTrue);
      expect(expense.isIncome, isFalse);
    });
  });
}
