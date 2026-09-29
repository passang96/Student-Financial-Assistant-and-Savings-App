import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/services/import_id_service.dart';

void main() {
  group('ImportIdService', () {
    test('creates a normalized stable import ID', () {
      expect(
        ImportIdService.create(
          fileName: 'September / Expenses.csv',
          transactionCount: 3,
          totalAmount: 125.5,
        ),
        'september___expenses_csv-3-125_50',
      );
    });
  });
}
