import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/csv_import_service.dart';
import '../../services/transaction_import_service.dart';
import 'import_preview_screen.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({
    super.key,
    this.csvImportService = const CsvImportService(),
    this.transactionWriter,
  });

  final CsvImportService csvImportService;
  final ImportedTransactionWriter? transactionWriter;

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  bool _isReading = false;
  String? _errorMessage;

  Future<void> _selectCsv() async {
    if (_isReading) {
      return;
    }

    setState(() {
      _isReading = true;
      _errorMessage = null;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      final transactions = widget.csvImportService.parse(bytes);

      if (!mounted) {
        return;
      }
      final importedCount = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => ImportPreviewScreen(
            fileName: file.name,
            transactions: transactions,
            transactionWriter: widget.transactionWriter,
          ),
        ),
      );

      if (importedCount != null && mounted) {
        Navigator.of(context).pop(importedCount);
      }
    } on CsvImportException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'The selected file could not be opened. Try '
              'exporting the statement as CSV again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isReading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Import Bank Statement')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.upload_file_outlined,
                    size: 72,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Import transactions from CSV',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Choose a bank statement with Date, Description and '
                    'Amount columns. Statements with separate Debit and '
                    'Credit columns are also supported.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What happens next',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const _ImportStep(
                            number: '1',
                            text: 'Your transactions are read from the file.',
                          ),
                          const _ImportStep(
                            number: '2',
                            text:
                                'Income, expenses and categories are '
                                'suggested automatically.',
                          ),
                          const _ImportStep(
                            number: '3',
                            text:
                                'You review and correct everything before '
                                'anything is saved.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, color: colors.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: colors.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isReading ? null : _selectCsv,
                    icon: _isReading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_open_outlined),
                    label: Text(
                      _isReading ? 'Reading statement…' : 'Select CSV File',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your file is only saved after you tap Import '
                    'Transactions on the preview screen.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImportStep extends StatelessWidget {
  const _ImportStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 13, child: Text(number)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
