import 'package:flutter/material.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late DateTime _selectedMonth;
  String _selectedType = 'All';
  String _selectedCategory = 'All';

  final List<String> _monthNames = [
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

  late final List<Map<String, dynamic>> _transactions;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);

    _transactions = [
      {
        'id': '1',
        'type': 'income',
        'category': 'Salary',
        'amount': 3200.00,
        'date': DateTime(now.year, now.month, 1),
        'notes': 'Monthly salary',
      },
      {
        'id': '2',
        'type': 'expense',
        'category': 'Rent',
        'amount': 1200.00,
        'date': DateTime(now.year, now.month, 3),
        'notes': 'Monthly rent',
      },
      {
        'id': '3',
        'type': 'expense',
        'category': 'Food',
        'amount': 85.50,
        'date': DateTime(now.year, now.month, 6),
        'notes': 'Weekly groceries',
      },
      {
        'id': '4',
        'type': 'expense',
        'category': 'Transport',
        'amount': 45.00,
        'date': DateTime(now.year, now.month - 1, 20),
        'notes': 'Public transport',
      },
    ];
  }

  List<DateTime> get _availableMonths {
    final now = DateTime.now();

    return List.generate(
      12,
      (index) => DateTime(now.year, now.month - index),
    );
  }

  List<String> get _categories {
    final categories = _transactions
        .map((transaction) => transaction['category'].toString())
        .toSet()
        .toList();

    categories.sort();
    return ['All', ...categories];
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((transaction) {
      final date = transaction['date'] as DateTime;

      final matchesMonth = date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month;

      final matchesType = _selectedType == 'All' ||
          transaction['type'] == _selectedType.toLowerCase();

      final matchesCategory = _selectedCategory == 'All' ||
          transaction['category'] == _selectedCategory;

      return matchesMonth && matchesType && matchesCategory;
    }).toList()
      ..sort(
        (first, second) =>
            (second['date'] as DateTime).compareTo(first['date'] as DateTime),
      );
  }

  String _monthLabel(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _deleteTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: const Text(
            'Are you sure you want to delete this transaction?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        _transactions.removeWhere(
          (item) => item['id'] == transaction['id'],
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
          ),
        );
      }
    }
  }

  Future<void> _editTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final amountController = TextEditingController(
      text: transaction['amount'].toString(),
    );

    final notesController = TextEditingController(
      text: transaction['notes'].toString(),
    );

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit transaction'),
          content: SizedBox(
            width: 400,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(
                  amountController.text.trim(),
                );

                if (amount == null || amount <= 0) {
                  return;
                }

                transaction['amount'] = amount;
                transaction['notes'] = notesController.text.trim();

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    amountController.dispose();
    notesController.dispose();

    if (updated == true) {
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _openAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
  }

  void _openAddIncome() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddIncomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFF14B8B1),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 210,
                          child: DropdownButtonFormField<DateTime>(
                            initialValue: _selectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              prefixIcon: Icon(Icons.calendar_month),
                              border: OutlineInputBorder(),
                            ),
                            items: _availableMonths.map((month) {
                              return DropdownMenuItem<DateTime>(
                                value: month,
                                child: Text(_monthLabel(month)),
                              );
                            }).toList(),
                            onChanged: (month) {
                              if (month != null) {
                                setState(() {
                                  _selectedMonth = month;
                                });
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              prefixIcon: Icon(Icons.swap_vert),
                              border: OutlineInputBorder(),
                            ),
                            items: ['All', 'Income', 'Expense'].map((type) {
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
                          width: 210,
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(Icons.category_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map((category) {
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
                  ],
                ),
              ),
              Expanded(
                child: filteredTransactions.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions found for this month.',
                          style: TextStyle(
                            fontSize: 17,
                            color: Color(0xFF667085),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction =
                              filteredTransactions[index];

                          final isIncome =
                              transaction['type'] == 'income';

                          final amount =
                              transaction['amount'] as double;

                          final date =
                              transaction['date'] as DateTime;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: CircleAvatar(
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
                              title: Text(
                                transaction['category'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${transaction['notes']}\n'
                                '${_dateLabel(date)}',
                              ),
                              isThreeLine: true,
                              trailing: SizedBox(
                                width: 170,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isIncome ? '+' : '-'}'
                                      '\$${amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isIncome
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
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
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}