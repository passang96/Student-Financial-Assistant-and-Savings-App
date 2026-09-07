import 'package:flutter/material.dart';

import '../../models/imported_transaction.dart';
import '../../services/transaction_import_service.dart';

enum CsvImportPeriod { all, weekly, fortnightly, monthly, custom }

extension CsvImportPeriodLabel on CsvImportPeriod {
  String get label {
    switch (this) {
      case CsvImportPeriod.all:
        return 'All Transactions';
      case CsvImportPeriod.weekly:
        return 'Weekly';
      case CsvImportPeriod.fortnightly:
        return 'Fortnightly';
      case CsvImportPeriod.monthly:
        return 'Monthly';
      case CsvImportPeriod.custom:
        return 'Custom Range';
    }
  }
}

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
  late List<ImportedTransaction> _allTransactions;

  CsvImportPeriod _selectedPeriod = CsvImportPeriod.all;

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  bool _isImporting = false;

  @override
  void initState() {
    super.initState();

    _allTransactions = List.of(widget.transactions);

    _transactionWriter = widget.transactionWriter ?? TransactionImportService();
  }

  List<ImportedTransaction> get _filteredTransactions {
    if (_allTransactions.isEmpty) {
      return [];
    }

    switch (_selectedPeriod) {
      case CsvImportPeriod.all:
        return List.of(_allTransactions);

      case CsvImportPeriod.weekly:
        return _filterRecentDays(7);

      case CsvImportPeriod.fortnightly:
        return _filterRecentDays(14);

      case CsvImportPeriod.monthly:
        return _filterLatestMonth();

      case CsvImportPeriod.custom:
        return _filterCustomRange();
    }
  }

  List<ImportedTransaction> _filterRecentDays(int days) {
    final latestDate = _latestTransactionDate;

    final startDate = DateTime(
      latestDate.year,
      latestDate.month,
      latestDate.day,
    ).subtract(Duration(days: days - 1));

    final endDate = DateTime(
      latestDate.year,
      latestDate.month,
      latestDate.day,
      23,
      59,
      59,
      999,
    );

    return _allTransactions.where((transaction) {
      return !transaction.date.isBefore(startDate) &&
          !transaction.date.isAfter(endDate);
    }).toList();
  }

  List<ImportedTransaction> _filterLatestMonth() {
    final latestDate = _latestTransactionDate;

    return _allTransactions.where((transaction) {
      return transaction.date.year == latestDate.year &&
          transaction.date.month == latestDate.month;
    }).toList();
  }

  List<ImportedTransaction> _filterCustomRange() {
    if (_customStartDate == null || _customEndDate == null) {
      return [];
    }

    final start = DateTime(
      _customStartDate!.year,
      _customStartDate!.month,
      _customStartDate!.day,
    );

    final end = DateTime(
      _customEndDate!.year,
      _customEndDate!.month,
      _customEndDate!.day,
      23,
      59,
      59,
      999,
    );

    return _allTransactions.where((transaction) {
      return !transaction.date.isBefore(start) &&
          !transaction.date.isAfter(end);
    }).toList();
  }

  DateTime get _latestTransactionDate {
    var latest = _allTransactions.first.date;

    for (final transaction in _allTransactions.skip(1)) {
      if (transaction.date.isAfter(latest)) {
        latest = transaction.date;
      }
    }

    return latest;
  }

  DateTime get _earliestTransactionDate {
    var earliest = _allTransactions.first.date;

    for (final transaction in _allTransactions.skip(1)) {
      if (transaction.date.isBefore(earliest)) {
        earliest = transaction.date;
      }
    }

    return earliest;
  }

  double get _incomeTotal => _filteredTransactions
      .where(
        (transaction) => transaction.type == ImportedTransactionType.income,
      )
      .fold(0, (total, transaction) => total + transaction.amount);

  double get _expenseTotal => _filteredTransactions
      .where(
        (transaction) => transaction.type == ImportedTransactionType.expense,
      )
      .fold(0, (total, transaction) => total + transaction.amount);

  void _updateTransaction(
    ImportedTransaction originalTransaction, {
    String? category,
    ImportedTransactionType? type,
  }) {
    final index = _allTransactions.indexOf(originalTransaction);

    if (index == -1) {
      return;
    }

    setState(() {
      _allTransactions[index] = _allTransactions[index].copyWith(
        category: category,
        type: type,
      );
    });
  }

  Future<void> _selectCustomDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? _earliestTransactionDate,
        end: _customEndDate ?? _latestTransactionDate,
      ),
      helpText: 'Select transactions to import',
      saveText: 'Apply',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _customStartDate = result.start;
      _customEndDate = result.end;
    });
  }

  Future<void> _importTransactions() async {
    final transactions = _filteredTransactions;

    if (_isImporting || transactions.isEmpty) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await _transactionWriter.importTransactions(
        transactions,
        fileName: widget.fileName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isImporting = false;
      });

      await _showImportResult(result);

      if (!mounted) {
        return;
      }

      /*
       * Only close the preview when at least one new
       * transaction was actually imported.
       *
       * If everything was a duplicate, keep the user
       * on the preview screen so they can choose another
       * period.
       */
      if (result.importedCount > 0) {
        Navigator.of(context).pop(result.importedCount);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isImporting = false;
      });

      final message = error is StateError
          ? error.message.toString()
          : 'Transactions could not be imported. '
                'Check your connection and try again.';

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

  Future<void> _showImportResult(TransactionImportResult result) async {
    final allDuplicates =
        result.importedCount == 0 && result.duplicateCount > 0;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Icon(
            allDuplicates ? Icons.info_outline : Icons.check_circle_outline,
          ),
          title: Text(
            allDuplicates ? 'No New Transactions' : 'Import Complete',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResultRow(
                label: 'Selected',
                value: result.selectedCount.toString(),
              ),
              const SizedBox(height: 8),
              _ResultRow(
                label: 'Imported',
                value: result.importedCount.toString(),
              ),
              const SizedBox(height: 8),
              _ResultRow(
                label: 'Duplicates skipped',
                value: result.duplicateCount.toString(),
              ),
              if (allDuplicates) ...[
                const SizedBox(height: 16),
                const Text(
                  'All transactions in this '
                  'selection are already in '
                  'your imported transaction '
                  'history.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String get _periodDescription {
    switch (_selectedPeriod) {
      case CsvImportPeriod.all:
        return '${_formatDate(_earliestTransactionDate)} – '
            '${_formatDate(_latestTransactionDate)}';

      case CsvImportPeriod.weekly:
        final end = _latestTransactionDate;

        final start = DateTime(
          end.year,
          end.month,
          end.day,
        ).subtract(const Duration(days: 6));

        return '${_formatDate(start)} – '
            '${_formatDate(end)}';

      case CsvImportPeriod.fortnightly:
        final end = _latestTransactionDate;

        final start = DateTime(
          end.year,
          end.month,
          end.day,
        ).subtract(const Duration(days: 13));

        return '${_formatDate(start)} – '
            '${_formatDate(end)}';

      case CsvImportPeriod.monthly:
        final latest = _latestTransactionDate;

        return '${_monthName(latest.month)} '
            '${latest.year}';

      case CsvImportPeriod.custom:
        if (_customStartDate == null || _customEndDate == null) {
          return 'Choose a start and end date';
        }

        return '${_formatDate(_customStartDate!)} – '
            '${_formatDate(_customEndDate!)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;

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
                          '${_allTransactions.length} '
                          'total transactions found '
                          'in CSV.',
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Import Period',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 8),

                        DropdownButtonFormField<CsvImportPeriod>(
                          initialValue: _selectedPeriod,
                          decoration: const InputDecoration(
                            labelText: 'Filter transactions',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.date_range_outlined),
                          ),
                          items: CsvImportPeriod.values.map((period) {
                            return DropdownMenuItem(
                              value: period,
                              child: Text(period.label),
                            );
                          }).toList(),
                          onChanged: _isImporting
                              ? null
                              : (period) {
                                  if (period == null) {
                                    return;
                                  }

                                  setState(() {
                                    _selectedPeriod = period;
                                  });

                                  if (period == CsvImportPeriod.custom) {
                                    _selectCustomDateRange();
                                  }
                                },
                        ),

                        if (_selectedPeriod == CsvImportPeriod.custom) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _isImporting
                                ? null
                                : _selectCustomDateRange,
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: const Text('Choose Custom Date Range'),
                          ),
                        ],

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_alt_outlined),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${_selectedPeriod.label}\n'
                                  '$_periodDescription',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          '${transactions.length} '
                          'transactions selected '
                          'for import.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),

                        const SizedBox(height: 16),

                        _ImportSummary(
                          income: _incomeTotal,
                          expenses: _expenseTotal,
                        ),

                        if (transactions.isEmpty) ...[
                          const SizedBox(height: 16),
                          const _EmptyFilterMessage(),
                        ],

                        const SizedBox(height: 18),

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
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];

                      return _TransactionPreviewCard(
                        key: ValueKey(
                          '${transaction.sourceRow}-'
                          '${transaction.category}-'
                          '${transaction.type.name}',
                        ),
                        transaction: transaction,
                        index: index,
                        enabled: !_isImporting,
                        onCategoryChanged: (category) {
                          _updateTransaction(transaction, category: category);
                        },
                        onTypeChanged: (type) {
                          _updateTransaction(transaction, type: type);
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
          onPressed: _isImporting || transactions.isEmpty
              ? null
              : _importTransactions,
          icon: _isImporting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: Text(
            _isImporting
                ? 'Importing…'
                : 'Import '
                      '${transactions.length} '
                      'Transactions',
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _EmptyFilterMessage extends StatelessWidget {
  const _EmptyFilterMessage();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No transactions were found '
              'for the selected period.',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
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
                      items: ImportedTransactionType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        );
                      }).toList(),
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
                  items: importedTransactionCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
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
