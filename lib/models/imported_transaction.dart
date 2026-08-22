enum ImportedTransactionType {
  income,
  expense;

  String get firestoreValue => name;

  String get label => switch (this) {
    ImportedTransactionType.income => 'Income',
    ImportedTransactionType.expense => 'Expense',
  };
}

const List<String> importedTransactionCategories = [
  'Food',
  'Transport',
  'Rent',
  'Bills',
  'Shopping',
  'Education/Study',
  'Entertainment',
  'Other',
];

class ImportedTransaction {
  const ImportedTransaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.sourceRow,
  });

  final DateTime date;
  final String description;

  /// Stored as a positive value. [type] carries the financial direction.
  final double amount;
  final ImportedTransactionType type;
  final String category;
  final int sourceRow;

  ImportedTransaction copyWith({
    DateTime? date,
    String? description,
    double? amount,
    ImportedTransactionType? type,
    String? category,
    int? sourceRow,
  }) {
    return ImportedTransaction(
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      sourceRow: sourceRow ?? this.sourceRow,
    );
  }
}
