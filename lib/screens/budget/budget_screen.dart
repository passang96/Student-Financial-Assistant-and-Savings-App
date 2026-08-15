import 'package:flutter/material.dart';
import 'category_management_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  double _monthlyBudget = 3000;
  late DateTime _selectedMonth;

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

  final List<Map<String, dynamic>> _categoryBudgets = [
    {'name': 'Rent', 'limit': 1200.0, 'spent': 1200.0},
    {'name': 'Food', 'limit': 600.0, 'spent': 350.0},
    {'name': 'Transport', 'limit': 300.0, 'spent': 145.0},
    {'name': 'Bills', 'limit': 350.0, 'spent': 220.0},
    {'name': 'Shopping', 'limit': 250.0, 'spent': 180.0},
    {'name': 'Education/Study', 'limit': 200.0, 'spent': 80.0},
    {'name': 'Entertainment', 'limit': 100.0, 'spent': 60.0},
    {'name': 'Other', 'limit': 100.0, 'spent': 40.0},
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  double get _totalSpent {
    return _categoryBudgets.fold(
      0,
      (total, category) => total + (category['spent'] as double),
    );
  }

  double get _remainingBudget {
    return _monthlyBudget - _totalSpent;
  }

  double get _overallProgress {
    if (_monthlyBudget <= 0) {
      return 0;
    }

    return (_totalSpent / _monthlyBudget).clamp(0.0, 1.0);
  }

  List<DateTime> get _availableMonths {
    final now = DateTime.now();

    return List.generate(
      12,
      (index) => DateTime(now.year, now.month - index),
    );
  }

  String _monthLabel(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Rent':
        return Icons.home_outlined;
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Transport':
        return Icons.directions_bus_outlined;
      case 'Bills':
        return Icons.receipt_long_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Education/Study':
        return Icons.school_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _progressColour(double progress) {
    if (progress >= 1) {
      return Colors.red;
    }

    if (progress >= 0.8) {
      return Colors.orange;
    }

    return const Color(0xFF14B8B1);
  }

  Future<void> _editMonthlyBudget() async {
    final controller = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(0),
    );

    final formKey = GlobalKey<FormState>();

    final newBudget = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Monthly Budget'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monthly budget limit',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');

                if (amount == null || amount <= 0) {
                  return 'Enter an amount greater than zero';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                    dialogContext,
                    double.parse(controller.text.trim()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8B1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

   

    if (newBudget != null) {
      setState(() {
        _monthlyBudget = newBudget;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monthly budget updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editCategoryLimit(
    Map<String, dynamic> category,
  ) async {
    final controller = TextEditingController(
      text: (category['limit'] as double).toStringAsFixed(0),
    );

    final formKey = GlobalKey<FormState>();

    final newLimit = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit ${category['name']} Budget'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Category budget limit',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');

                if (amount == null || amount <= 0) {
                  return 'Enter an amount greater than zero';
                }

                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                    dialogContext,
                    double.parse(controller.text.trim()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8B1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

   

    if (newLimit != null) {
      setState(() {
        category['limit'] = newLimit;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text(
            '${category['name']} budget updated',
         )),
        );
      }
    }
  }

  void _openCategoryManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingColour =
        _remainingBudget < 0 ? Colors.red : Colors.green;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Budget'),
        backgroundColor: const Color(0xFF14B8B1),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<DateTime>(
                  initialValue: _selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Budget month',
                    prefixIcon: Icon(Icons.calendar_month),
                    filled: true,
                    fillColor: Colors.white,
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
                const SizedBox(height: 16),

                Card(
                  color: const Color(0xFF14B8B1),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Monthly Budget',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit monthly budget',
                              onPressed: _editMonthlyBudget,
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '\$${_monthlyBudget.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _overallProgress,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(10),
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Spent: '
                                '\$${_totalSpent.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              'Remaining: '
                              '\$${_remainingBudget.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Spending',
                        amount: _totalSpent,
                        icon: Icons.payments_outlined,
                        colour: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Budget Remaining',
                        amount: _remainingBudget,
                        icon: Icons.savings_outlined,
                        colour: remainingColour,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Category Budgets',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _openCategoryManagement,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8B1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categoryBudgets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final category = _categoryBudgets[index];
                    final limit = category['limit'] as double;
                    final spent = category['spent'] as double;
                    final remaining = limit - spent;
                    final progress = limit <= 0
                        ? 0.0
                        : (spent / limit).clamp(0.0, 1.0);

                    return Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      const Color(0xFFE6FFFC),
                                  child: Icon(
                                    _categoryIcon(
                                      category['name'].toString(),
                                    ),
                                    color: const Color(0xFF14B8B1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category['name'].toString(),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Limit: '
                                        '\$${limit.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF667085),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit category budget',
                                  onPressed: () =>
                                      _editCategoryLimit(category),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 9,
                              borderRadius: BorderRadius.circular(10),
                              backgroundColor:
                                  const Color(0xFFE5E7EB),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _progressColour(progress),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Spent: '
                                    '\$${spent.toStringAsFixed(2)}',
                                  ),
                                ),
                                Text(
                                  'Remaining: '
                                  '\$${remaining.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: remaining < 0
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Category spending and remaining amounts are '
                          'calculated automatically from transactions.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color colour;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.colour,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: colour, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: colour,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}