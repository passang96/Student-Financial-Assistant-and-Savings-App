import 'package:flutter/material.dart';

import '../../models/imported_transaction.dart';
import '../../services/transaction_import_service.dart';

class ImportPreviewScreen extends StatefulWidget {
  const ImportPreviewScreen({
    super.key,
    required this.fileName,
    required this.transactions,
    this.transactionWriter,
  });

  final String fileName;
  final List<ImportedTransaction> transactions;
  final ImportedTransactionWriter? transactionWriter;

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  late final ImportedTransactionWriter _transactionWriter;
  late List<ImportedTransaction> _transactions;
  bool _isImporting = false;

  double get _incomeTotal => _transactions
      .where(
        (transaction) => transaction.type == ImportedTransactionType.income,
      )
      .fold(0, (total, transaction) => total + transaction.amount);

  double get _expenseTotal => _transactions
      .where(
        (transaction) => transaction.type == ImportedTransactionType.expense,
      )
      .fold(0, (total, transaction) => total + transaction.amount);

  @override
  void initState() {
    super.initState();
    _transactions = List.of(widget.transactions);
    _transactionWriter = widget.transactionWriter ?? TransactionImportService();
  }

  void _updateTransaction(
    int index, {
    String? category,
    ImportedTransactionType? type,
  }) {
    setState(() {
      _transactions[index] = _transactions[index].copyWith(
        category: category,
        type: type,
      );
    });
  }

  Future<void> _importTransactions() async {
    if (_isImporting || _transactions.isEmpty) {
      return;
    }

    setState(() => _isImporting = true);
    try {
      await _transactionWriter.importTransactions(
        _transactions,
        fileName: widget.fileName,
      );

      if (mounted) {
        Navigator.of(context).pop(_transactions.length);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isImporting = false);
      final message = error is StateError
          ? error.message.toString()
          : 'Transactions could not be imported. Check your connection and '
                'try again.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Preview')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_transactions.length} transactions found. '
                          'Review the suggested type and category before '
                          'importing.',
                        ),
                        const SizedBox(height: 16),
                        _ImportSummary(
                          income: _incomeTotal,
                          expenses: _expenseTotal,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Transactions',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _TransactionPreviewCard(
                        key: ValueKey(
                          '${transaction.sourceRow}-${transaction.category}-'
                          '${transaction.type.name}',
                        ),
                        transaction: transaction,
                        index: index,
                        enabled: !_isImporting,
                        onCategoryChanged: (category) {
                          _updateTransaction(index, category: category);
                        },
                        onTypeChanged: (type) {
                          _updateTransaction(index, type: type);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: FilledButton.icon(
          key: const Key('import-transactions-button'),
          onPressed: _isImporting ? null : _importTransactions,
          icon: _isImporting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(_isImporting ? 'Importing…' : 'Import Transactions'),
        ),
      ),
    );
  }
}

class _ImportSummary extends StatelessWidget {
  const _ImportSummary({required this.income, required this.expenses});

  final double income;
  final double expenses;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Income',
            amount: income,
            icon: Icons.arrow_downward,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            label: 'Expenses',
            amount: expenses,
            icon: Icons.arrow_upward,
            color: colors.error,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionPreviewCard extends StatelessWidget {
  const _TransactionPreviewCard({
    super.key,
    required this.transaction,
    required this.index,
    required this.enabled,
    required this.onCategoryChanged,
    required this.onTypeChanged,
  });

  final ImportedTransaction transaction;
  final int index;
  final bool enabled;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<ImportedTransactionType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final amountColor = transaction.type == ImportedTransactionType.income
        ? colors.primary
        : colors.error;

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(_formatDate(transaction.date)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${transaction.type == ImportedTransactionType.income ? '+' : '-'}'
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final typeField =
                    DropdownButtonFormField<ImportedTransactionType>(
                      key: Key('type-$index'),
                      initialValue: transaction.type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        isDense: true,
                      ),
                      items: ImportedTransactionType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: enabled
                          ? (type) {
                              if (type != null) {
                                onTypeChanged(type);
                              }
                            }
                          : null,
                    );

                final categoryField = DropdownButtonFormField<String>(
                  key: Key('category-$index'),
                  initialValue: transaction.category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    isDense: true,
                  ),
                  items: importedTransactionCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: enabled
                      ? (category) {
                          if (category != null) {
                            onCategoryChanged(category);
                          }
                        }
                      : null,
                );

                if (constraints.maxWidth < 500) {
                  return Column(
                    children: [
                      typeField,
                      const SizedBox(height: 12),
                      categoryField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: typeField),
                    const SizedBox(width: 12),
                    Expanded(child: categoryField),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
