class ImportIdService {
  const ImportIdService();

  /// Generates a deterministic ID for an individual imported transaction.
  ///
  /// This allows the application to detect the same bank transaction even
  /// when it is imported from a different CSV file or from a different
  /// selected date range.
  String generateTransactionId({
    required DateTime date,
    required String description,
    required double amount,
    required String type,
  }) {
    final normalisedDate =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final normalisedDescription = description.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    final normalisedType = type.trim().toLowerCase();

    final rawValue =
        '$normalisedDate|'
        '$normalisedDescription|'
        '${amount.toStringAsFixed(2)}|'
        '$normalisedType';

    return _stableHash(rawValue);
  }

  /// Generates an identifier for an import session.
  ///
  /// This is useful for recording CSV import history, but transaction-level
  /// IDs are used for the actual duplicate protection.
  String generateImportId({
    required String fileName,
    required int transactionCount,
    required double totalAmount,
    String? periodKey,
  }) {
    final normalisedFileName = fileName.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    final rawValue =
        '$normalisedFileName|'
        '$transactionCount|'
        '${totalAmount.toStringAsFixed(2)}|'
        '${periodKey ?? 'all'}';

    return _stableHash(rawValue);
  }

  /// FNV-1a 64-bit hash.
  ///
  /// Unlike Dart's Object.hashCode, this produces the same result for the
  /// same input every time the application runs.
  String _stableHash(String value) {
    const int fnvOffsetBasis = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    const int mask64 = 0xFFFFFFFFFFFFFFFF;

    var hash = fnvOffsetBasis;

    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & mask64;
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }
}
