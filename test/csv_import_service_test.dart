import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/models/imported_transaction.dart';
import 'package:student_financial_assistant/services/csv_import_service.dart';

void main() {
  const service = CsvImportService();

  Uint8List csvBytes(String value) => Uint8List.fromList(utf8.encode(value));

  test('parses signed amounts and suggests categories', () {
    final transactions = service.parse(
      csvBytes(
        'Date,Description,Amount\n'
        '20/08/2026,"Woolworths, Sydney",-42.75\n'
        '19/08/2026,Salary,1200.00',
      ),
    );

    expect(transactions, hasLength(2));
    expect(transactions.first.date, DateTime(2026, 8, 20));
    expect(transactions.first.description, 'Woolworths, Sydney');
    expect(transactions.first.amount, 42.75);
    expect(transactions.first.type, ImportedTransactionType.expense);
    expect(transactions.first.category, 'Food');
    expect(transactions.last.type, ImportedTransactionType.income);
    expect(transactions.last.category, 'Other');
  });

  test('supports preambles, semicolons, and debit/credit columns', () {
    final transactions = service.parse(
      csvBytes(
        'Account statement;;;;\n'
        'Posted Date;Details;Debit;Credit;Balance\n'
        '18 Aug 2026;Opal recharge;25.00;;100.00\n'
        '19 Aug 2026;Refund;;10.50;110.50',
      ),
    );

    expect(transactions, hasLength(2));
    expect(transactions.first.type, ImportedTransactionType.expense);
    expect(transactions.first.category, 'Transport');
    expect(transactions.last.type, ImportedTransactionType.income);
    expect(transactions.last.amount, 10.50);
  });

  test('uses an explicit type column when amounts are unsigned', () {
    final transactions = service.parse(
      csvBytes(
        'Transaction Date,Memo,Amount,Transaction Type\n'
        '2026-08-17,Netflix,19.99,Debit\n'
        '2026-08-18,Scholarship,500,Credit',
      ),
    );

    expect(transactions.first.type, ImportedTransactionType.expense);
    expect(transactions.first.category, 'Entertainment');
    expect(transactions.last.type, ImportedTransactionType.income);
  });

  test('reports missing required headers clearly', () {
    expect(
      () => service.parse(csvBytes('When,What,Cost\n20/08/2026,Lunch,12')),
      throwsA(
        isA<CsvImportException>().having(
          (error) => error.message,
          'message',
          contains('Date, Description, and Amount'),
        ),
      ),
    );
  });

  test('reports the source row for invalid data', () {
    expect(
      () => service.parse(
        csvBytes('Date,Description,Amount\n31/02/2026,Lunch,-12'),
      ),
      throwsA(
        isA<CsvImportException>().having(
          (error) => error.message,
          'message',
          contains('Row 2'),
        ),
      ),
    );
  });
}
