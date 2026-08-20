class ImportIdService {
  static String create({
    required String fileName,
    required int transactionCount,
    required double totalAmount,
  }) {
    final value =
        '$fileName-$transactionCount-${totalAmount.toStringAsFixed(2)}';

    return value
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll('.', '_');
  }
}
