import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../services/goal_service.dart';
import '../../utils/date_period.dart';
import '../../widgets/period_selector.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GoalService _goalService = GoalService();

  DatePeriod _selectedPeriod = DatePeriod.thisMonth;

  DateTime? _customStartDate;
  DateTime? _customEndDate;

  String _money(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
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

  DateRange? _previousDateRange() {
    final current = _activeDateRange();

    if (current == null) {
      return null;
    }

    final currentStart = DateTime(
      current.start.year,
      current.start.month,
      current.start.day,
    );

    final currentEnd = DateTime(
      current.end.year,
      current.end.month,
      current.end.day,
    );

    final days = currentEnd.difference(currentStart).inDays + 1;

    final previousEnd = currentStart.subtract(const Duration(days: 1));

    final previousStart = previousEnd.subtract(Duration(days: days - 1));

    return DateRange(
      previousStart,
      DateTime(
        previousEnd.year,
        previousEnd.month,
        previousEnd.day,
        23,
        59,
        59,
        999,
      ),
    );
  }

  List<Map<String, dynamic>> _convertTransactions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) {
      final data = doc.data();

      final rawDate = data['date'];

      final date = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();

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

  List<Map<String, dynamic>> _transactionsInRange(
    List<Map<String, dynamic>> transactions,
    DateRange? range,
  ) {
    if (range == null) {
      return [];
    }

    return transactions.where((transaction) {
      final date = transaction['date'] as DateTime;

      return range.contains(date);
    }).toList();
  }

  double _income(List<Map<String, dynamic>> transactions) {
    return transactions
        .where((transaction) => transaction['type'] == 'income')
        .fold<double>(
          0,
          (total, transaction) => total + (transaction['amount'] as double),
        );
  }

  double _expenses(List<Map<String, dynamic>> transactions) {
    return transactions
        .where((transaction) => transaction['type'] == 'expense')
        .fold<double>(
          0,
          (total, transaction) => total + (transaction['amount'] as double),
        );
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

  Map<String, double> _categoryExpenses(
    List<Map<String, dynamic>> transactions,
  ) {
    final categories = <String, double>{};

    for (final transaction in transactions) {
      if (transaction['type'] != 'expense') {
        continue;
      }

      final category = transaction['category']?.toString() ?? 'Other';

      final amount = transaction['amount'] as double;

      categories[category] = (categories[category] ?? 0) + amount;
    }

    return categories;
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

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? now.subtract(const Duration(days: 7)),
        end: _customEndDate ?? now,
      ),
      helpText: 'Select Report Period',
      confirmText: 'Apply',
      cancelText: 'Cancel',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPeriod = DatePeriod.custom;
      _customStartDate = picked.start;
      _customEndDate = picked.end;
    });
  }

  String _periodTitle() {
    if (_selectedPeriod == DatePeriod.custom &&
        _customStartDate != null &&
        _customEndDate != null) {
      return '${_dateLabel(_customStartDate!)} - '
          '${_dateLabel(_customEndDate!)}';
    }

    return _selectedPeriod.label;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestoreService.getTransactions(),
      builder: (context, transactionSnapshot) {
        if (transactionSnapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Could not load reports.\n\n'
                '${transactionSnapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (!transactionSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final allTransactions = _convertTransactions(
          transactionSnapshot.data!.docs,
        );

        final currentTransactions = _transactionsInRange(
          allTransactions,
          _activeDateRange(),
        );

        final previousTransactions = _transactionsInRange(
          allTransactions,
          _previousDateRange(),
        );

        final currentIncome = _income(currentTransactions);

        final currentExpenses = _expenses(currentTransactions);

        final currentNet = currentIncome - currentExpenses;

        final previousIncome = _income(previousTransactions);

        final previousExpenses = _expenses(previousTransactions);

        final previousNet = previousIncome - previousExpenses;

        final categories = _categoryExpenses(currentTransactions);

        final sortedCategories = categories.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _goalService.getGoals(),
          builder: (context, goalSnapshot) {
            if (goalSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Could not load savings data.\n\n'
                    '${goalSnapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            double totalSavings = 0;
            int savingsGoalCount = 0;

            if (goalSnapshot.hasData) {
              savingsGoalCount = goalSnapshot.data!.docs.length;

              for (final goal in goalSnapshot.data!.docs) {
                final data = goal.data();

                totalSavings +=
                    (data['currentAmount'] as num?)?.toDouble() ?? 0;
              }
            }

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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PeriodSelector(
                          selectedPeriod: _selectedPeriod,
                          onPeriodChanged: _handlePeriodChanged,
                          customStartDate: _customStartDate,
                          customEndDate: _customEndDate,
                          onCustomRangeRequested: _pickCustomRange,
                        ),

                        const SizedBox(height: 20),

                        Text(
                          _periodTitle(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D3557),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${currentTransactions.length} transaction'
                          '${currentTransactions.length == 1 ? '' : 's'} analysed',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool wide = constraints.maxWidth >= 650;

                            final width = wide
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth;

                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: width,
                                  child: _buildSummaryCard(
                                    title: 'Income',
                                    amount: currentIncome,
                                    comparison: _percentageChange(
                                      currentIncome,
                                      previousIncome,
                                    ),
                                    icon: Icons.arrow_downward,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _buildSummaryCard(
                                    title: 'Expenses',
                                    amount: currentExpenses,
                                    comparison: _percentageChange(
                                      currentExpenses,
                                      previousExpenses,
                                    ),
                                    icon: Icons.arrow_upward,
                                    color: Colors.red,
                                    lowerIsBetter: true,
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _buildSummaryCard(
                                    title: 'Net Cash Flow',
                                    amount: currentNet,
                                    comparison: _percentageChange(
                                      currentNet,
                                      previousNet,
                                    ),
                                    icon: Icons.account_balance_wallet_outlined,
                                    color: const Color(0xFF0E9F99),
                                  ),
                                ),
                                SizedBox(
                                  width: width,
                                  child: _buildSavingsCard(
                                    savings: totalSavings,
                                    goalCount: savingsGoalCount,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        _buildComparisonCard(
                          currentIncome: currentIncome,
                          previousIncome: previousIncome,
                          currentExpenses: currentExpenses,
                          previousExpenses: previousExpenses,
                          currentNet: currentNet,
                          previousNet: previousNet,
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

                        const SizedBox(height: 6),

                        const Text(
                          'See where your money went during the selected period.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (sortedCategories.isEmpty)
                          _buildEmptyCategories()
                        else
                          ...sortedCategories.map(
                            (entry) => _buildCategoryCard(
                              category: entry.key,
                              amount: entry.value,
                              totalExpenses: currentExpenses,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required double comparison,
    required IconData icon,
    required Color color,
    bool lowerIsBetter = false,
  }) {
    final increased = comparison > 0;

    Color comparisonColor;

    if (comparison == 0) {
      comparisonColor = const Color(0xFF64748B);
    } else if (lowerIsBetter) {
      comparisonColor = increased ? Colors.red : Colors.green;
    } else {
      comparisonColor = increased ? Colors.green : Colors.red;
    }

    String comparisonText;

    if (comparison == 0) {
      comparisonText = 'No change vs previous period';
    } else {
      comparisonText =
          '${comparison > 0 ? '+' : ''}'
          '${comparison.toStringAsFixed(1)}% '
          'vs previous period';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),

          const SizedBox(height: 5),

          Text(
            _money(amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3557),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            comparisonText,
            style: TextStyle(
              color: comparisonColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard({required double savings, required int goalCount}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF2E8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.savings_outlined, color: Color(0xFF7C3AED)),
          ),

          const SizedBox(height: 12),

          const Text(
            'Savings Goals',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),

          const SizedBox(height: 5),

          Text(
            _money(savings),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3557),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            goalCount == 0
                ? 'No savings goals yet'
                : goalCount == 1
                ? 'Across 1 savings goal'
                : 'Across $goalCount savings goals',
            style: const TextStyle(
              color: Color(0xFF7C3AED),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard({
    required double currentIncome,
    required double previousIncome,
    required double currentExpenses,
    required double previousExpenses,
    required double currentNet,
    required double previousNet,
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
            'Current vs Previous Period',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'The previous period uses the same number of days immediately before the selected period.',
            style: TextStyle(color: Colors.white70, fontSize: 11),
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
            title: 'Net Cash Flow',
            current: _money(currentNet),
            previous: _money(previousNet),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String category,
    required double amount,
    required double totalExpenses,
  }) {
    final percentage = totalExpenses > 0 ? amount / totalExpenses : 0.0;

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
              const CircleAvatar(
                backgroundColor: Color(0xFFE1FAF8),
                child: Icon(Icons.category_outlined, color: Color(0xFF0E9F99)),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              value: percentage.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF14B8B1),
            ),
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(percentage * 100).toStringAsFixed(1)}% of selected expenses',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCategories() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.pie_chart_outline, size: 42, color: Color(0xFF94A3B8)),

          SizedBox(height: 10),

          Text(
            'No expense data for this period',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.title,
    required this.current,
    required this.previous,
  });

  final String title;
  final String current;
  final String previous;

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

            const SizedBox(height: 2),

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
