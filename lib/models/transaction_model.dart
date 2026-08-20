import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String description;
  final double amount;
  final String type;
  final String category;
  final DateTime date;

  // manual or csv
  final String source;

  // Identifies a CSV import
  final String? importId;

  final DateTime? createdAt;

  TransactionModel({
    this.id = '',
    required this.userId,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.source = 'manual',
    this.importId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'source': source,
      'importId': importId,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return TransactionModel(
      id: documentId,
      userId: map['userId'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] ?? 'Expense',
      category: map['category'] ?? 'Other',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      source: map['source'] ?? 'manual',
      importId: map['importId'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory TransactionModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw Exception('Transaction data is empty');
    }

    return TransactionModel.fromMap(data, doc.id);
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? description,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    String? source,
    String? importId,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      source: source ?? this.source,
      importId: importId ?? this.importId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isCsv {
    return source.toLowerCase() == 'csv';
  }

  bool get isIncome {
    return type.toLowerCase() == 'income';
  }

  bool get isExpense {
    return type.toLowerCase() == 'expense';
  }
}
