import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../models/imported_transaction.dart';

class CsvImportException implements Exception {
  const CsvImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CsvImportService {
  const CsvImportService();

  static const _dateHeaders = {
    'date',
    'transactiondate',
    'posteddate',
    'valuedate',
  };
  static const _descriptionHeaders = {
    'description',
    'details',
    'transactiondetails',
    'narration',
    'narrative',
    'merchant',
    'merchantname',
    'memo',
    'particulars',
  };
  static const _amountHeaders = {'amount', 'transactionamount', 'value'};
  static const _debitHeaders = {
    'debit',
    'debitamount',
    'withdrawal',
    'withdrawals',
    'withdrawalamount',
    'moneyout',
  };
  static const _creditHeaders = {
    'credit',
    'creditamount',
    'deposit',
    'deposits',
    'depositamount',
    'moneyin',
  };
  static const _typeHeaders = {'type', 'transactiontype', 'debitcredit'};

  static const Map<String, List<String>> _categoryKeywords = {
    'Food': [
      'grocery',
      'groceries',
      'supermarket',
      'coles',
      'woolworths',
      'aldi',
      'restaurant',
      'cafe',
      'takeaway',
      'uber eats',
      'doordash',
      'menulog',
      'mcdonald',
      'mcdonalds',
      'food',
    ],
    'Transport': [
      'opal',
      'transport',
      'train',
      'bus',
      'uber',
      'taxi',
      'fuel',
      'petrol',
      'parking',
      'toll',
    ],
    'Rent': ['rent', 'landlord', 'real estate', 'tenancy'],
    'Bills': [
      'electricity',
      'energy',
      'water bill',
      'gas bill',
      'internet',
      'mobile',
      'phone bill',
      'telstra',
      'optus',
      'vodafone',
      'insurance',
      'utility',
    ],
    'Shopping': [
      'amazon',
      'ebay',
      'kmart',
      'target',
      'big w',
      'shopping',
      'retail',
      'clothing',
      'fashion',
    ],
    'Education/Study': [
      'tuition',
      'university',
      'tafe',
      'textbook',
      'course',
      'school',
      'stationery',
      'officeworks',
      'study',
    ],
    'Entertainment': [
      'netflix',
      'spotify',
      'cinema',
      'movie',
      'gaming',
      'steam',
      'concert',
      'entertainment',
    ],
  };

  List<ImportedTransaction> parse(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const CsvImportException('The selected CSV file is empty.');
    }

    var contents = utf8.decode(bytes, allowMalformed: true);
    if (contents.startsWith('\ufeff')) {
      contents = contents.substring(1);
    }

    late final List<List<dynamic>> rows;
    try {
      rows = csv.decode(contents);
    } catch (_) {
      throw const CsvImportException(
        'The selected file could not be read as CSV.',
      );
    }

    if (rows.isEmpty) {
      throw const CsvImportException('The selected CSV file is empty.');
    }

    final mapping = _findHeaders(rows);
    final transactions = <ImportedTransaction>[];

    for (var index = mapping.rowIndex + 1; index < rows.length; index++) {
      final row = rows[index];
      if (_isEmptyRow(row)) {
        continue;
      }

      final sourceRow = index + 1;
      final rawDate = _cell(row, mapping.dateIndex);
      final description = _cell(row, mapping.descriptionIndex).trim();

      if (rawDate.trim().isEmpty && description.isEmpty) {
        continue;
      }
      if (description.isEmpty) {
        throw CsvImportException('Row $sourceRow has no description.');
      }

      final date = _parseDate(rawDate);
      if (date == null) {
        throw CsvImportException(
          'Row $sourceRow has an unsupported date: "$rawDate".',
        );
      }

      final parsedAmount = _amountAndType(row, mapping, sourceRow);
      transactions.add(
        ImportedTransaction(
          date: date,
          description: description,
          amount: parsedAmount.amount,
          type: parsedAmount.type,
          category: suggestCategory(description),
          sourceRow: sourceRow,
        ),
      );
    }

    if (transactions.isEmpty) {
      throw const CsvImportException(
        'No transactions were found beneath the CSV headers.',
      );
    }

    return List.unmodifiable(transactions);
  }

  String suggestCategory(String description) {
    final normalized = description.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      if (entry.value.any((keyword) => _containsKeyword(normalized, keyword))) {
        return entry.key;
      }
    }
    return 'Other';
  }

  bool _containsKeyword(String description, String keyword) {
    final escapedKeyword = RegExp.escape(keyword.toLowerCase());
    return RegExp(
      '(^|[^a-z0-9])$escapedKeyword([^a-z0-9]|\$)',
    ).hasMatch(description);
  }

  _HeaderMapping _findHeaders(List<List<dynamic>> rows) {
    final rowsToCheck = rows.length < 10 ? rows.length : 10;
    for (var rowIndex = 0; rowIndex < rowsToCheck; rowIndex++) {
      final headers = rows[rowIndex]
          .map((value) => _normalizeHeader(value.toString()))
          .toList();
      final dateIndex = _indexOfAny(headers, _dateHeaders);
      final descriptionIndex = _indexOfAny(headers, _descriptionHeaders);
      final amountIndex = _indexOfAny(headers, _amountHeaders);
      final debitIndex = _indexOfAny(headers, _debitHeaders);
      final creditIndex = _indexOfAny(headers, _creditHeaders);

      if (dateIndex != null &&
          descriptionIndex != null &&
          (amountIndex != null || debitIndex != null || creditIndex != null)) {
        return _HeaderMapping(
          rowIndex: rowIndex,
          dateIndex: dateIndex,
          descriptionIndex: descriptionIndex,
          amountIndex: amountIndex,
          debitIndex: debitIndex,
          creditIndex: creditIndex,
          typeIndex: _indexOfAny(headers, _typeHeaders),
        );
      }
    }

    throw const CsvImportException(
      'Could not find Date, Description, and Amount headers. '
      'Debit/Credit columns are also supported.',
    );
  }

  _ParsedAmount _amountAndType(
    List<dynamic> row,
    _HeaderMapping mapping,
    int sourceRow,
  ) {
    if (mapping.amountIndex != null) {
      final rawAmount = _cell(row, mapping.amountIndex!);
      final signedAmount = _parseMoney(rawAmount);
      if (signedAmount == null || signedAmount == 0) {
        throw CsvImportException(
          'Row $sourceRow has an unsupported amount: "$rawAmount".',
        );
      }

      final explicitType = mapping.typeIndex == null
          ? null
          : _parseType(_cell(row, mapping.typeIndex!));
      return _ParsedAmount(
        amount: signedAmount.abs(),
        type:
            explicitType ??
            (signedAmount < 0
                ? ImportedTransactionType.expense
                : ImportedTransactionType.income),
      );
    }

    final debit = mapping.debitIndex == null
        ? null
        : _parseMoney(_cell(row, mapping.debitIndex!));
    final credit = mapping.creditIndex == null
        ? null
        : _parseMoney(_cell(row, mapping.creditIndex!));
    final hasDebit = debit != null && debit != 0;
    final hasCredit = credit != null && credit != 0;

    if (hasDebit == hasCredit) {
      throw CsvImportException(
        'Row $sourceRow must contain either a debit or a credit amount.',
      );
    }

    if (hasCredit) {
      return _ParsedAmount(
        amount: credit.abs(),
        type: ImportedTransactionType.income,
      );
    }
    return _ParsedAmount(
      amount: debit!.abs(),
      type: ImportedTransactionType.expense,
    );
  }

  ImportedTransactionType? _parseType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('income') ||
        normalized.contains('credit') ||
        normalized == 'cr' ||
        normalized.contains('deposit')) {
      return ImportedTransactionType.income;
    }
    if (normalized.contains('expense') ||
        normalized.contains('debit') ||
        normalized == 'dr' ||
        normalized.contains('withdrawal')) {
      return ImportedTransactionType.expense;
    }
    return null;
  }

  double? _parseMoney(String value) {
    var normalized = value.trim().toUpperCase();
    if (normalized.isEmpty || normalized == '-' || normalized == '—') {
      return null;
    }

    final isParenthesized =
        normalized.startsWith('(') && normalized.endsWith(')');
    final isDebit = RegExp(r'\bDR$').hasMatch(normalized);
    final isCredit = RegExp(r'\bCR$').hasMatch(normalized);
    normalized = normalized
        .replaceAll(RegExp(r'\b(?:AUD|USD|NZD|GBP|EUR)\b'), '')
        .replaceAll(RegExp(r'[^0-9,\.\-+]'), '');

    if (normalized.contains(',') && normalized.contains('.')) {
      normalized = normalized.replaceAll(',', '');
    } else if (RegExp(r',\d{1,2}$').hasMatch(normalized)) {
      normalized = normalized.replaceAll(',', '.');
    } else {
      normalized = normalized.replaceAll(',', '');
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return null;
    }
    if (isParenthesized || isDebit) {
      return -parsed.abs();
    }
    if (isCredit) {
      return parsed.abs();
    }
    return parsed;
  }

  DateTime? _parseDate(String value) {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) {
      return null;
    }

    final isoDate = DateTime.tryParse(cleanValue);
    if (isoDate != null) {
      return DateTime(isoDate.year, isoDate.month, isoDate.day);
    }

    final numeric = RegExp(
      r'^(\d{1,4})[\/\.\-](\d{1,2})[\/\.\-](\d{1,4})$',
    ).firstMatch(cleanValue);
    if (numeric != null) {
      final first = int.parse(numeric.group(1)!);
      final middle = int.parse(numeric.group(2)!);
      final last = int.parse(numeric.group(3)!);
      final yearFirst = numeric.group(1)!.length == 4;
      final year = _fourDigitYear(yearFirst ? first : last);
      final month = middle;
      final day = yearFirst ? last : first;
      final dayFirstDate = _validDate(year, month, day);
      if (dayFirstDate != null || yearFirst || middle <= 12) {
        return dayFirstDate;
      }

      // Accept unambiguous MM/DD/YYYY exports while preferring the Australian
      // DD/MM/YYYY convention when both interpretations are valid.
      return _validDate(year, first, middle);
    }

    final namedMonth = RegExp(
      r'^(\d{1,2})[\s\-]([A-Za-z]{3,9})[\s,\-]+(\d{2,4})$',
    ).firstMatch(cleanValue);
    if (namedMonth != null) {
      final day = int.parse(namedMonth.group(1)!);
      final month = _monthNumber(namedMonth.group(2)!);
      final year = _fourDigitYear(int.parse(namedMonth.group(3)!));
      if (month != null) {
        return _validDate(year, month, day);
      }
    }
    return null;
  }

  int _fourDigitYear(int year) {
    if (year >= 100) {
      return year;
    }
    return year >= 70 ? 1900 + year : 2000 + year;
  }

  DateTime? _validDate(int year, int month, int day) {
    if (year < 1900 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  int? _monthNumber(String name) {
    const months = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };
    return months[name.toLowerCase()];
  }

  String _normalizeHeader(String value) {
    return value.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
  }

  int? _indexOfAny(List<String> headers, Set<String> accepted) {
    for (var index = 0; index < headers.length; index++) {
      if (accepted.contains(headers[index])) {
        return index;
      }
    }
    return null;
  }

  String _cell(List<dynamic> row, int index) {
    return index < row.length ? row[index].toString() : '';
  }

  bool _isEmptyRow(List<dynamic> row) {
    return row.every((value) => value.toString().trim().isEmpty);
  }
}

class _HeaderMapping {
  const _HeaderMapping({
    required this.rowIndex,
    required this.dateIndex,
    required this.descriptionIndex,
    required this.amountIndex,
    required this.debitIndex,
    required this.creditIndex,
    required this.typeIndex,
  });

  final int rowIndex;
  final int dateIndex;
  final int descriptionIndex;
  final int? amountIndex;
  final int? debitIndex;
  final int? creditIndex;
  final int? typeIndex;
}

class _ParsedAmount {
  const _ParsedAmount({required this.amount, required this.type});

  final double amount;
  final ImportedTransactionType type;
}
