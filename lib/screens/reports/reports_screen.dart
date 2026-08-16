import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return user.uid;
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

  String _monthLabel(DateTime date) {
    return '${_monthName(date.month)} ${date.year}';
  }

  List<DateTime> _availableMonths() {
    final now = DateTime.now();

    return List.generate(12, (index) => DateTime(now.year, now.month - index));
  }

  DateTime _previousMonth(DateTime month) {
    return DateTime(month.year, month.month - 1);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _transactionsForMonth(
    DateTime month,
  ) {
    final start = DateTime(month.year, month.month, 1);

    final end = DateTime(month.year, month.month + 1, 1);

    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _budgetForMonth(
    DateTime month,
  ) {
    final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('budgets')
        .doc(monthKey)
        .snapshots();
  }

  Map<String, dynamic> _calculateReport(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    double income = 0;
    double expenses = 0;

    final Map<String, double> categorySpending = {};

    for (final document in snapshot.docs) {
      final data = document.data();

      final String type = data['type']?.toString().toLowerCase() ?? '';

      final double amount = (data['amount'] as num?)?.toDouble() ?? 0;

      if (type == 'income') {
        income += amount;
      }

      if (type == 'expense') {
        expenses += amount;

        final String category =
            data['category']?.toString().trim().isNotEmpty == true
            ? data['category'].toString().trim()
            : 'Other';

        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
      }
    }

    final double savings = income - expenses;

    final double savingsRate = income > 0 ? (savings / income) * 100 : 0;

    return {
      'income': income,
      'expenses': expenses,
      'savings': savings,
      'savingsRate': savingsRate,
      'categories': categorySpending,
    };
  }

  double _percentageChange(double current, double previous) {
    if (previous == 0) {
      if (current == 0) {
        return 0;
      }

      return 100;
    }

    return ((current - previous) / previous) * 100;
  }

  Map<String, double> _readCategoryBudgets(
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
  ) {
    final Map<String, double> result = {};

    final data = snapshot?.data();

    if (data == null) {
      return result;
    }

    final raw = data['categoryBudgets'];

    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is num) {
          result[key.toString()] = value.toDouble();
        }
      });
    }

    return result;
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
        return Colors.blue;

      case 'food':
        return Colors.orange;

      case 'transport':
        return Colors.green;

      case 'bills':
        return Colors.purple;

      case 'shopping':
        return Colors.pink;

      case 'education/study':
        return Colors.indigo;

      case 'entertainment':
        return Colors.deepOrange;

      case 'medical':
      case 'health':
        return Colors.red;

      default:
        return Colors.teal;
    }
  }

  double _categoryProgress(double spent, double limit, double totalExpenses) {
    if (limit > 0) {
      final value = spent / limit;

      return value.clamp(0.0, 1.0);
    }

    if (totalExpenses > 0) {
      final value = spent / totalExpenses;

      return value.clamp(0.0, 1.0);
    }

    return 0;
  }

  String _money(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final previousMonth = _previousMonth(_selectedMonth);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _transactionsForMonth(_selectedMonth),
      builder: (context, currentSnapshot) {
        if (currentSnapshot.hasError) {
          return _errorScreen('Could not load report', currentSnapshot.error);
        }

        if (!currentSnapshot.hasData) {
          return _loadingScreen();
        }

        final currentReport = _calculateReport(currentSnapshot.data!);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _transactionsForMonth(previousMonth),
          builder: (context, previousSnapshot) {
            if (previousSnapshot.hasError) {
              return _errorScreen(
                'Could not load previous month',
                previousSnapshot.error,
              );
            }

            if (!previousSnapshot.hasData) {
              return _loadingScreen();
            }

            final previousReport = _calculateReport(previousSnapshot.data!);

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _budgetForMonth(_selectedMonth),
              builder: (context, budgetSnapshot) {
                final categoryBudgets = _readCategoryBudgets(
                  budgetSnapshot.data,
                );

                return _buildReportScreen(
                  currentReport: currentReport,
                  previousReport: previousReport,
                  categoryBudgets: categoryBudgets,
                  previousMonth: previousMonth,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReportScreen({
    required Map<String, dynamic> currentReport,
    required Map<String, dynamic> previousReport,
    required Map<String, double> categoryBudgets,
    required DateTime previousMonth,
  }) {
    final double income = currentReport['income'] as double;

    final double expenses = currentReport['expenses'] as double;

    final double savings = currentReport['savings'] as double;

    final double savingsRate = currentReport['savingsRate'] as double;

    final double previousIncome = previousReport['income'] as double;

    final double previousExpenses = previousReport['expenses'] as double;

    final double previousSavings = previousReport['savings'] as double;

    final Map<String, double> categorySpending = Map<String, double>.from(
      currentReport['categories'] as Map,
    );

    final incomeComparison = _percentageChange(income, previousIncome);

    final expenseComparison = _percentageChange(expenses, previousExpenses);

    final savingsComparison = _percentageChange(savings, previousSavings);

    final double previousSavingsRate = previousIncome > 0
        ? (previousSavings / previousIncome) * 100
        : 0;

    final savingsRateComparison = savingsRate - previousSavingsRate;

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Financial Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D3557),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(),

            const SizedBox(height: 20),

            const Text(
              'Monthly Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D3557),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Income',
                    amount: income,
                    comparison: incomeComparison,
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Expenses',
                    amount: expenses,
                    comparison: expenseComparison,
                    icon: Icons.arrow_upward,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Savings',
                    amount: savings,
                    comparison: savingsComparison,
                    icon: Icons.savings_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Savings Rate',
                    amount: savingsRate,
                    comparison: savingsRateComparison,
                    icon: Icons.percent,
                    color: Colors.purple,
                    isPercentage: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildMonthComparison(
              currentIncome: income,
              previousIncome: previousIncome,
              currentExpenses: expenses,
              previousExpenses: previousExpenses,
              currentSavings: savings,
              previousSavings: previousSavings,
              previousMonth: previousMonth,
            ),

            const SizedBox(height: 24),

            const Text(
              'Category Spending',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D3557),
              ),
            ),

            const SizedBox(height: 12),

            if (sortedCategories.isEmpty)
              _buildNoCategoryData()
            else
              ...sortedCategories.map((entry) {
                final limit = categoryBudgets[entry.key] ?? 0;

                return _buildCategoryCard(
                  name: entry.key,
                  amount: entry.value,
                  limit: limit,
                  totalExpenses: expenses,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final months = _availableMonths();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          value: _selectedMonth,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: months.map((month) {
            return DropdownMenuItem<DateTime>(
              value: month,
              child: Text(_monthLabel(month)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMonth = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required double comparison,
    required IconData icon,
    required Color color,
    bool isPercentage = false,
  }) {
    final bool increased = comparison >= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),

          const SizedBox(height: 10),

          Text(title, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 5),

          Text(
            isPercentage ? '${amount.toStringAsFixed(1)}%' : _money(amount),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3557),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${increased ? '+' : ''}'
            '${comparison.toStringAsFixed(1)}% vs previous',
            style: TextStyle(
              color: increased ? Colors.green : Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthComparison({
    required double currentIncome,
    required double previousIncome,
    required double currentExpenses,
    required double previousExpenses,
    required double currentSavings,
    required double previousSavings,
    required DateTime previousMonth,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3557),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current vs Previous Month',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            '${_monthLabel(_selectedMonth)} vs '
            '${_monthLabel(previousMonth)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),

          const SizedBox(height: 16),

          _ComparisonRow(
            title: 'Income',
            current: _money(currentIncome),
            previous: _money(previousIncome),
          ),

          const SizedBox(height: 14),

          _ComparisonRow(
            title: 'Expenses',
            current: _money(currentExpenses),
            previous: _money(previousExpenses),
          ),

          const SizedBox(height: 14),

          _ComparisonRow(
            title: 'Savings',
            current: _money(currentSavings),
            previous: _money(previousSavings),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String name,
    required double amount,
    required double limit,
    required double totalExpenses,
  }) {
    final color = _categoryColor(name);

    final progress = _categoryProgress(amount, limit, totalExpenses);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(Icons.category_outlined, color: color),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Text(
                _money(amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              limit > 0
                  ? '${(amount / limit * 100).toStringAsFixed(1)}% of \$${limit.toStringAsFixed(2)} budget'
                  : '${(progress * 100).toStringAsFixed(1)}% of monthly expenses',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCategoryData() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.analytics_outlined, size: 42, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'No expense data for this month',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _loadingScreen() {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F7FB),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _errorScreen(String message, Object? error) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '$message\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String title;
  final String current;
  final String previous;

  const _ComparisonRow({
    required this.title,
    required this.current,
    required this.previous,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(color: Colors.white70)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              current,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Previous: $previous',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
