import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../utils/date_period.dart';
import '../../widgets/period_selector.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'csv_import_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  DatePeriod _selectedPeriod = DatePeriod.thisMonth;

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  String _selectedType = 'All';
  String _selectedCategory = 'All';

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _currentPeriodLabel() {
    if (_selectedPeriod == DatePeriod.custom &&
        _customStartDate != null &&
        _customEndDate != null) {
      return '${_dateLabel(_customStartDate!)} - '
          '${_dateLabel(_customEndDate!)}';
    }

    return _selectedPeriod.label;
  }

  List<Map<String, dynamic>> _convertDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) {
      final data = doc.data();

      final Timestamp? timestamp = data['date'] is Timestamp
          ? data['date'] as Timestamp
          : null;

      final DateTime date = timestamp?.toDate() ?? DateTime.now();

      return {
        'id': doc.id,
        'type': data['type']?.toString() ?? '',
        'category': data['category']?.toString() ?? 'Other',
        'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
        'date': date,
        'notes': data['notes']?.toString() ?? '',
      };
    }).toList();
  }

  List<String> _categoriesFrom(List<Map<String, dynamic>> transactions) {
    final categories = transactions
        .map((transaction) => transaction['category'].toString())
        .where((category) => category.trim().isNotEmpty)
        .toSet()
        .toList();

    categories.sort();

    return ['All', ...categories];
  }

  DateRange? _activeDateRange() {
    if (_selectedPeriod == DatePeriod.custom) {
      if (_customStartDate == null || _customEndDate == null) {
        return null;
      }

      return resolveDateRange(
        DatePeriod.custom,
        customStart: _customStartDate,
        customEnd: _customEndDate,
      );
    }

    return resolveDateRange(_selectedPeriod);
  }

  List<Map<String, dynamic>> _filterTransactions(
    List<Map<String, dynamic>> transactions,
  ) {
    final dateRange = _activeDateRange();

    if (dateRange == null) {
      return [];
    }

    final filtered = transactions.where((transaction) {
      final date = transaction['date'] as DateTime;

      final matchesDate = dateRange.contains(date);

      final matchesType =
          _selectedType == 'All' ||
          transaction['type'] == _selectedType.toLowerCase();

      final matchesCategory =
          _selectedCategory == 'All' ||
          transaction['category'] == _selectedCategory;

      return matchesDate && matchesType && matchesCategory;
    }).toList();

    filtered.sort(
      (first, second) =>
          (second['date'] as DateTime).compareTo(first['date'] as DateTime),
    );

    return filtered;
  }

  double _calculateIncome(List<Map<String, dynamic>> transactions) {
    return transactions
        .where((transaction) => transaction['type'] == 'income')
        .fold<double>(
          0,
          (total, transaction) => total + (transaction['amount'] as double),
        );
  }

  double _calculateExpenses(List<Map<String, dynamic>> transactions) {
    return transactions
        .where((transaction) => transaction['type'] == 'expense')
        .fold<double>(
          0,
          (total, transaction) => total + (transaction['amount'] as double),
        );
  }

  Future<void> _handlePeriodChanged(DatePeriod period) async {
    if (period == DatePeriod.custom) {
      await _pickCustomRange();
      return;
    }

    setState(() {
      _selectedPeriod = period;
      _customStartDate = null;
      _customEndDate = null;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();

    final DateTime initialStart =
        _customStartDate ?? now.subtract(const Duration(days: 7));

    final DateTime initialEnd = _customEndDate ?? now;

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Select Transaction Period',
      confirmText: 'Apply',
      cancelText: 'Cancel',
    );

    if (pickedRange == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPeriod = DatePeriod.custom;
      _customStartDate = pickedRange.start;
      _customEndDate = pickedRange.end;
    });
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: const Text(
            'Are you sure you want to delete this transaction?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _firestoreService.deleteTransaction(transaction['id'].toString());

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete transaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editTransaction(Map<String, dynamic> transaction) async {
    final amountController = TextEditingController(
      text: (transaction['amount'] as double).toStringAsFixed(2),
    );

    final notesController = TextEditingController(
      text: transaction['notes'].toString(),
    );

    final String type = transaction['type'].toString();

    String selectedCategory = transaction['category'].toString();

    DateTime selectedDate = transaction['date'] as DateTime;

    final List<String> availableCategories = type == 'income'
        ? ['Salary', 'Business', 'Allowance', 'Scholarship', 'Gift', 'Other']
        : [
            'Rent',
            'Food',
            'Transport',
            'Bills',
            'Shopping',
            'Education/Study',
            'Entertainment',
            'Other',
          ];

    if (!availableCategories.contains(selectedCategory)) {
      availableCategories.add(selectedCategory);
    }

    final bool? updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Transaction'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: availableCategories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_dateLabel(selectedDate)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final double? amount = double.tryParse(
                      amountController.text.trim(),
                    );

                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount')),
                      );

                      return;
                    }

                    try {
                      await _firestoreService.updateTransaction(
                        transactionId: transaction['id'].toString(),
                        type: type,
                        amount: amount,
                        category: selectedCategory,
                        date: selectedDate,
                        notes: notesController.text.trim(),
                      );

                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      if (!dialogContext.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Could not update transaction: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    notesController.dispose();

    if (!mounted) {
      return;
    }

    if (updated == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _openAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
  }

  void _openAddIncome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddIncomeScreen()),
    );
  }

  Future<void> _openCsvImport() async {
    final importedCount = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const CsvImportScreen()),
    );

    if (!mounted) {
      return;
    }

    if (importedCount != null && importedCount > 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$importedCount transaction'
              '${importedCount == 1 ? '' : 's'} '
              'imported successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
    }
  }

  Widget _buildSummaryCard({
    required double income,
    required double expenses,
    required int transactionCount,
  }) {
    final double balance = income - expenses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Color(0xFF0E9F99)),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  _currentPeriodLabel(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),

              Text(
                '$transactionCount transaction'
                '${transactionCount == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: 'Income',
                  value: income,
                  color: Colors.green,
                ),
              ),

              Container(height: 46, width: 1, color: const Color(0xFFE2E8F0)),

              Expanded(
                child: _SummaryValue(
                  label: 'Expenses',
                  value: expenses,
                  color: Colors.red,
                ),
              ),

              Container(height: 46, width: 1, color: const Color(0xFFE2E8F0)),

              Expanded(
                child: _SummaryValue(
                  label: 'Net',
                  value: balance,
                  color: balance >= 0 ? const Color(0xFF0E9F99) : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFF14B8B1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Import Bank Transactions',
            onPressed: _openCsvImport,
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load transactions.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final transactions = _convertDocuments(docs);

          final categories = _categoriesFrom(transactions);

          if (!categories.contains(_selectedCategory)) {
            _selectedCategory = 'All';
          }

          final filteredTransactions = _filterTransactions(transactions);

          final double filteredIncome = _calculateIncome(filteredTransactions);

          final double filteredExpenses = _calculateExpenses(
            filteredTransactions,
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        PeriodSelector(
                          selectedPeriod: _selectedPeriod,
                          onPeriodChanged: _handlePeriodChanged,
                          customStartDate: _customStartDate,
                          customEndDate: _customEndDate,
                          onCustomRangeRequested: _pickCustomRange,
                        ),

                        const SizedBox(height: 14),

                        _buildSummaryCard(
                          income: filteredIncome,
                          expenses: filteredExpenses,
                          transactionCount: filteredTransactions.length,
                        ),

                        const SizedBox(height: 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: 220,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedType,
                                      decoration: const InputDecoration(
                                        labelText: 'Transaction Type',
                                        prefixIcon: Icon(Icons.swap_vert),
                                        border: OutlineInputBorder(),
                                      ),
                                      items: ['All', 'Income', 'Expense'].map((
                                        type,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: type,
                                          child: Text(type),
                                        );
                                      }).toList(),
                                      onChanged: (type) {
                                        if (type != null) {
                                          setState(() {
                                            _selectedType = type;
                                          });
                                        }
                                      },
                                    ),
                                  ),

                                  SizedBox(
                                    width: 220,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedCategory,
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                        prefixIcon: Icon(
                                          Icons.category_outlined,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      items: categories.map((category) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(category),
                                        );
                                      }).toList(),
                                      onChanged: (category) {
                                        if (category != null) {
                                          setState(() {
                                            _selectedCategory = category;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _openAddIncome,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Income'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _openAddExpense,
                                      icon: const Icon(Icons.remove),
                                      label: const Text('Add Expense'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _openCsvImport,
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: const Text('Import Bank Transactions'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0E9F99),
                                    side: const BorderSide(
                                      color: Color(0xFF14B8B1),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),

                        const SizedBox(height: 10),

                        if (filteredTransactions.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 40,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 42,
                                  color: Color(0xFF94A3B8),
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  'No transactions found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  'There are no transactions matching '
                                  '${_currentPeriodLabel()} and your current filters.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...filteredTransactions.map((transaction) {
                            final bool isIncome =
                                transaction['type'] == 'income';

                            final double amount =
                                transaction['amount'] as double;

                            final DateTime date =
                                transaction['date'] as DateTime;

                            final String notes = transaction['notes']
                                .toString();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: isIncome
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      child: Icon(
                                        isIncome
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isIncome
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction['category'].toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            notes.isEmpty ? 'No notes' : notes,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF667085),
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          Text(
                                            _dateLabel(date),
                                            maxLines: 1,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF98A2B3),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${isIncome ? '+' : '-'}'
                                          '\$${amount.toStringAsFixed(2)}',
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isIncome
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),

                                        const SizedBox(height: 2),

                                        SizedBox(
                                          width: 36,
                                          height: 32,
                                          child: PopupMenuButton<String>(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                              Icons.more_vert,
                                              size: 22,
                                              color: Color(0xFF667085),
                                            ),
                                            onSelected: (action) {
                                              if (action == 'edit') {
                                                _editTransaction(transaction);
                                              } else if (action == 'delete') {
                                                _deleteTransaction(transaction);
                                              }
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit_outlined,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_outline,
                                                      size: 20,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '\$${value.toStringAsFixed(2)}',
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
