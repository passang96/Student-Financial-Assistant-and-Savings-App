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

  List<ImportedTransaction> parse(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const CsvImportException('The selected CSV file is empty.');
    }

    String content;

    try {
      content = utf8.decode(bytes);
    } on FormatException {
      content = latin1.decode(bytes);
    }

    content = content.replaceFirst('\uFEFF', '').trim();

    if (content.isEmpty) {
      throw const CsvImportException('The selected CSV file is empty.');
    }

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(content);

    if (rows.isEmpty) {
      throw const CsvImportException(
        'The CSV file does not contain any transactions.',
      );
    }

    /*
     * CommBank transaction exports commonly use:
     *
     * Date, Amount, Description, Balance
     *
     * but do NOT include a header row.
     *
     * Example:
     *
     * 21/08/2026,-63.97,Merchant Name,+574.64
     *
     * We detect that format before trying the normal
     * header-based CSV parser.
     */
    if (_looksLikeCommBankFormat(rows)) {
      return _parseCommBankRows(rows);
    }

    return _parseHeaderBasedRows(rows);
  }

  bool _looksLikeCommBankFormat(List<List<dynamic>> rows) {
    if (rows.isEmpty) {
      return false;
    }

    final firstRow = rows.first;

    if (firstRow.length < 3) {
      return false;
    }

    final firstValue = firstRow[0]?.toString().trim() ?? '';
    final secondValue = firstRow[1]?.toString().trim() ?? '';

    final date = _tryParseDate(firstValue);
    final amount = _tryParseAmount(secondValue);

    return date != null && amount != null;
  }

  List<ImportedTransaction> _parseCommBankRows(List<List<dynamic>> rows) {
    final transactions = <ImportedTransaction>[];

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];

      if (_isEmptyRow(row) || row.length < 3) {
        continue;
      }

      try {
        final dateText = _valueAt(row, 0);
        final amountText = _valueAt(row, 1);
        final description = _valueAt(row, 2).trim();

        if (description.isEmpty) {
          continue;
        }

        final date = _parseDate(dateText);
        final rawAmount = _parseAmount(amountText);

        if (rawAmount == 0) {
          continue;
        }

        final type = rawAmount < 0
            ? ImportedTransactionType.expense
            : ImportedTransactionType.income;

        final amount = rawAmount.abs();

        transactions.add(
          ImportedTransaction(
            date: date,
            description: description,
            amount: amount,
            type: type,
            category: _suggestCategory(description, type),
            sourceRow: rowIndex + 1,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    if (transactions.isEmpty) {
      throw const CsvImportException(
        'No valid CommBank transactions could be found in this CSV file.',
      );
    }

    return transactions;
  }

  List<ImportedTransaction> _parseHeaderBasedRows(List<List<dynamic>> rows) {
    if (rows.length < 2) {
      throw const CsvImportException(
        'The CSV file does not contain any transactions.',
      );
    }

    final headers = rows.first
        .map((value) => _normaliseHeader(value.toString()))
        .toList();

    final dateIndex = _findHeaderIndex(headers, [
      'date',
      'transactiondate',
      'valuedate',
      'posteddate',
    ]);

    final descriptionIndex = _findHeaderIndex(headers, [
      'description',
      'details',
      'transactiondescription',
      'narrative',
      'merchant',
      'memo',
      'particulars',
    ]);

    final amountIndex = _findHeaderIndex(headers, [
      'amount',
      'transactionamount',
    ]);

    final debitIndex = _findHeaderIndex(headers, [
      'debit',
      'withdrawal',
      'withdrawals',
      'moneyout',
    ]);

    final creditIndex = _findHeaderIndex(headers, [
      'credit',
      'deposit',
      'deposits',
      'moneyin',
    ]);

    if (dateIndex == -1) {
      throw const CsvImportException(
        'Could not find a Date column in the CSV file.',
      );
    }

    if (descriptionIndex == -1) {
      throw const CsvImportException(
        'Could not find a Description column in the CSV file.',
      );
    }

    if (amountIndex == -1 && debitIndex == -1 && creditIndex == -1) {
      throw const CsvImportException(
        'Could not find an Amount, Debit or Credit column in the CSV file.',
      );
    }

    final transactions = <ImportedTransaction>[];

    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];

      if (_isEmptyRow(row)) {
        continue;
      }

      try {
        final dateText = _valueAt(row, dateIndex);

        final description = _valueAt(row, descriptionIndex).trim();

        if (description.isEmpty) {
          continue;
        }

        final date = _parseDate(dateText);

        double amount;
        ImportedTransactionType type;

        if (amountIndex != -1) {
          final rawAmount = _parseAmount(_valueAt(row, amountIndex));

          if (rawAmount == 0) {
            continue;
          }

          type = rawAmount < 0
              ? ImportedTransactionType.expense
              : ImportedTransactionType.income;

          amount = rawAmount.abs();
        } else {
          final debit = debitIndex == -1
              ? 0.0
              : _parseAmount(_valueAt(row, debitIndex)).abs();

          final credit = creditIndex == -1
              ? 0.0
              : _parseAmount(_valueAt(row, creditIndex)).abs();

          if (debit == 0 && credit == 0) {
            continue;
          }

          if (credit > 0 && debit == 0) {
            type = ImportedTransactionType.income;
            amount = credit;
          } else {
            type = ImportedTransactionType.expense;
            amount = debit > 0 ? debit : credit;
          }
        }

        transactions.add(
          ImportedTransaction(
            date: date,
            description: description,
            amount: amount,
            type: type,
            category: _suggestCategory(description, type),
            sourceRow: rowIndex + 1,
          ),
        );
      } catch (_) {
        continue;
      }
    }

    if (transactions.isEmpty) {
      throw const CsvImportException(
        'No valid transactions could be found in this CSV file.',
      );
    }

    return transactions;
  }

  String _normaliseHeader(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  int _findHeaderIndex(List<String> headers, List<String> possibleNames) {
    for (final name in possibleNames) {
      final index = headers.indexOf(name);

      if (index != -1) {
        return index;
      }
    }

    return -1;
  }

  String _valueAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) {
      return '';
    }

    return row[index]?.toString() ?? '';
  }

  bool _isEmptyRow(List<dynamic> row) {
    return row.every(
      (value) => value == null || value.toString().trim().isEmpty,
    );
  }

  double _parseAmount(String value) {
    final parsed = _tryParseAmount(value);

    if (parsed == null) {
      return 0;
    }

    return parsed;
  }

  double? _tryParseAmount(String value) {
    var cleaned = value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    var negative = false;

    if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
      negative = true;

      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    cleaned = cleaned
        .replaceAll('\$', '')
        .replaceAll(',', '')
        .replaceAll('AUD', '')
        .replaceAll('aud', '')
        .replaceAll('+', '')
        .trim();

    final parsed = double.tryParse(cleaned);

    if (parsed == null) {
      return null;
    }

    return negative ? -parsed.abs() : parsed;
  }

  DateTime _parseDate(String value) {
    final date = _tryParseDate(value);

    if (date == null) {
      throw FormatException('Unsupported date: $value');
    }

    return date;
  }

  DateTime? _tryParseDate(String value) {
    final cleaned = value.trim();

    if (cleaned.isEmpty) {
      return null;
    }

    final isoDate = DateTime.tryParse(cleaned);

    if (isoDate != null) {
      return DateTime(isoDate.year, isoDate.month, isoDate.day);
    }

    final parts = cleaned.split(RegExp(r'[/\-.]'));

    if (parts.length != 3) {
      return null;
    }

    final first = int.tryParse(parts[0]);

    final second = int.tryParse(parts[1]);

    final third = int.tryParse(parts[2]);

    if (first == null || second == null || third == null) {
      return null;
    }

    if (parts[0].length == 4) {
      return DateTime(first, second, third);
    }

    var year = third;

    if (year < 100) {
      year += 2000;
    }

    // Australian banking date format:
    // DD/MM/YYYY
    return DateTime(year, second, first);
  }

  String _suggestCategory(String description, ImportedTransactionType type) {
    final text = description.toLowerCase();

    /*
     * Positive transactions can also be automatically
     * classified when the description gives us enough
     * information.
     */
    if (type == ImportedTransactionType.income) {
      if (text.contains('salary') ||
          text.contains('payroll') ||
          text.contains('wages')) {
        return 'Salary';
      }

      if (text.contains('scholarship')) {
        return 'Scholarship';
      }

      if (text.contains('cash deposit')) {
        return 'Other';
      }

      if (text.contains('transfer from') ||
          text.contains('fast transfer from')) {
        return 'Other';
      }

      if (text.contains('commsec') || text.contains('dividend')) {
        return 'Other';
      }

      return 'Other';
    }

    const categoryKeywords = <String, List<String>>{
      'Food': [
        'grocery',
        'groceries',
        'coles',
        'woolworths',
        'aldi',
        'restaurant',
        'cafe',
        'coffee',
        'mcdonald',
        'kfc',
        'hungry jack',
        'uber eats',
        'ubereats',
        'doordash',
        'menulog',
        'food',
        'monkey temple',
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
        'shell',
        'bp ',
        'caltex',
        'ampol',
        'parking',
        'toll',
      ],
      'Rent': ['rent', 'rental', 'real estate', 'property'],
      'Bills': [
        'electricity',
        'energy',
        'gas bill',
        'water bill',
        'internet',
        'telstra',
        'optus',
        'vodafone',
        'phone bill',
        'insurance',
      ],
      'Shopping': [
        'amazon',
        'kmart',
        'target',
        'big w',
        'ebay',
        'shopping',
        'ikea',
        'myer',
        'david jones',
        'afterpay',
      ],
      'Education/Study': [
        'university',
        'college',
        'tuition',
        'course',
        'textbook',
        'student',
        'education',
        'school',
      ],
      'Entertainment': [
        'netflix',
        'spotify',
        'cinema',
        'movie',
        'gaming',
        'steam',
        'playstation',
        'xbox',
        'disney',
        'youtube premium',
      ],
    };

    for (final entry in categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return 'Other';
  }
}
