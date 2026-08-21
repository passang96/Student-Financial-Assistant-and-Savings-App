import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedMonth = 'August 2026';

  String selectedPeriod = 'Current Month';

  DateTime? fromDate;
DateTime? toDate;

final List<String> reportPeriods = [
  'This Week',
  'Last Week',
  'This Fortnight',
  'Last Fortnight',
  'This Month',
  'Last Month',
  'Custom Range',
];

  final List<String> months = [
    'August 2026',
    'July 2026',
    'June 2026',
  ];

  final List<Map<String, dynamic>> categorySpending = [
    {
      'name': 'Rent',
      'amount': 1200.0,
      'percentage': 0.60,
      'color': Colors.blue,
    },
    {
      'name': 'Food',
      'amount': 450.0,
      'percentage': 0.45,
      'color': Colors.orange,
    },
    {
      'name': 'Transport',
      'amount': 220.0,
      'percentage': 0.30,
      'color': Colors.green,
    },
    {
      'name': 'Bills',
      'amount': 300.0,
      'percentage': 0.40,
      'color': Colors.purple,
    },
    {
      'name': 'Shopping',
      'amount': 180.0,
      'percentage': 0.25,
      'color': Colors.pink,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
  _buildPeriodSelector(),
  const SizedBox(height: 20),

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
                    amount: 5000,
                    comparison: 8,
                    icon: Icons.arrow_downward,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Expenses',
                    amount: 2350,
                    comparison: -5,
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
                    amount: 2650,
                    comparison: 12,
                    icon: Icons.savings_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Savings Rate',
                    amount: 53,
                    comparison: 6,
                    icon: Icons.percent,
                    color: Colors.purple,
                    isPercentage: true,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildMonthComparison(),
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

            ...categorySpending.map(_buildCategoryCard),
          ],
        ),
      ),
    );
  }
Widget _buildPeriodSelector() {
  return DropdownButtonFormField<String>(
    initialValue: selectedPeriod,
    decoration: const InputDecoration(
      labelText: 'Select Period',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.calendar_month),
    ),
    items: const [
      DropdownMenuItem(
        value: 'Current Month',
        child: Text('Current Month'),
      ),
      DropdownMenuItem(
        value: 'Previous Month',
        child: Text('Previous Month'),
      ),
    ],
    onChanged: (value) {
      if (value != null) {
        setState(() {
          selectedPeriod = value;
        });
      }
    },
  );
}
Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMonth,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: months.map((month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Text(month),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedMonth = value;
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
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 5),
          Text(
            isPercentage
                ? '${amount.toStringAsFixed(0)}%'
                : '\$${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3557),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${increased ? '+' : ''}${comparison.toStringAsFixed(0)}% vs previous',
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

  Widget _buildMonthComparison() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D3557),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current vs Previous Month',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _ComparisonRow(
            title: 'Income',
            current: '\$5,000',
            previous: '\$4,630',
          ),
          SizedBox(height: 14),
          _ComparisonRow(
            title: 'Expenses',
            current: '\$2,350',
            previous: '\$2,474',
          ),
          SizedBox(height: 14),
          _ComparisonRow(
            title: 'Savings',
            current: '\$2,650',
            previous: '\$2,156',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final Color categoryColor = category['color'] as Color;
    final double percentage = category['percentage'] as double;
    final double amount = category['amount'] as double;

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
                backgroundColor: categoryColor.withValues(alpha: 0.15),
                child: Icon(
                  Icons.category_outlined,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(percentage * 100).toStringAsFixed(0)}% of category budget',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70),
          ),
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
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}