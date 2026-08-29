class ImportIdService {
  const ImportIdService();

  String generateImportId({
    required String fileName,
    required int transactionCount,
    required double totalAmount,
  }) {
    final normalisedFileName = fileName.trim().toLowerCase();

    final rawValue =
        '$normalisedFileName|$transactionCount|${totalAmount.toStringAsFixed(2)}';

    // Produce a stable positive identifier for the import.
    return rawValue.hashCode.abs().toString();
  }
}
