import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

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

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  List<DateTime> get _availableMonths {
    final now = DateTime.now();

    return List.generate(12, (index) => DateTime(now.year, now.month - index));
  }

  String _monthLabel(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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

  List<Map<String, dynamic>> _filterTransactions(
    List<Map<String, dynamic>> transactions,
  ) {
    final filtered = transactions.where((transaction) {
      final date = transaction['date'] as DateTime;

      final matchesMonth =
          date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month;

      final matchesType =
          _selectedType == 'All' ||
          transaction['type'] == _selectedType.toLowerCase();

      final matchesCategory =
          _selectedCategory == 'All' ||
          transaction['category'] == _selectedCategory;

      return matchesMonth && matchesType && matchesCategory;
    }).toList();

    filtered.sort(
      (first, second) =>
          (second['date'] as DateTime).compareTo(first['date'] as DateTime),
    );

    return filtered;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFF14B8B1),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load transactions.\n\n${snapshot.error}',
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

          return Center(
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
                              final transaction = filteredTransactions[index];

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
                                    '${notes.isEmpty ? 'No notes' : notes}\n'
                                    '${_dateLabel(date)}',
                                  ),
                                  isThreeLine: true,
                                  trailing: SizedBox(
                                    width: 170,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${isIncome ? '+' : '-'}'
                                            '\$${amount.toStringAsFixed(2)}',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isIncome
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
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
          );
        },
      ),
    );
  }
}
