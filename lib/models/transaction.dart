/// Type of a transaction — used for totals and filtering.
enum TransactionType { income, expense }

/// A single financial transaction (manually entered or CSV-imported).
///
/// TODO(Passang): This is the frontend-facing model. When wiring up
/// Firestore, map documents in the `transactions` collection to/from this
/// class (e.g. a `fromFirestore(DocumentSnapshot doc)` factory and a
/// `toMap()` method), keeping field names consistent with what Pema's CSV
/// import service writes.
class Transaction {
  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.source = 'manual',
  });

  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;

  /// 'manual' or 'csv' — set by Pema's CSV import (source: "csv").
  final String source;
}

/// Standard category list, matching Pema's CSV auto-categorisation options.
const List<String> kTransactionCategories = [
  'Food',
  'Transport',
  'Rent',
  'Bills',
  'Shopping',
  'Education/Study',
  'Entertainment',
  'Other',
];
