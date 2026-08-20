import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/models/imported_transaction.dart';
import 'package:student_financial_assistant/screens/transactions/import_preview_screen.dart';
import 'package:student_financial_assistant/services/transaction_import_service.dart';

void main() {
  testWidgets('passes category corrections to the transaction writer', (
    tester,
  ) async {
    final writer = _RecordingWriter();
    final transaction = ImportedTransaction(
      date: DateTime(2026, 8, 20),
      description: 'Campus purchase',
      amount: 24.50,
      type: ImportedTransactionType.expense,
      category: 'Other',
      sourceRow: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ImportPreviewScreen(
          fileName: 'statement.csv',
          transactions: [transaction],
          transactionWriter: writer,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('category-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Education/Study').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-transactions-button')));
    await tester.pumpAndSettle();

    expect(writer.received, isNotNull);
    expect(writer.received!.single.category, 'Education/Study');
    expect(find.text('Test import stopped.'), findsOneWidget);
  });
}

class _RecordingWriter implements ImportedTransactionWriter {
  List<ImportedTransaction>? received;

  @override
  Future<void> importTransactions(
    List<ImportedTransaction> transactions,
  ) async {
    received = List.of(transactions);
    throw StateError('Test import stopped.');
  }
}
