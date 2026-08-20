import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/transaction.dart';
import '../../utils/date_period.dart';
import '../../widgets/period_selector.dart';
import '../../widgets/transaction_summary_card.dart';
import '../../widgets/transaction_tile.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  // TODO(Passang): Replace this in-memory mock list with a Firestore
  // stream/query for the signed-in user's transactions. When the selected
  // period changes, resolveDateRange() below gives you the exact
  // start/end DateTime to use in a Firestore range query
  // (where('date', isGreaterThanOrEqualTo: ...).where('date',
  // isLessThanOrEqualTo: ...)).
  final List<Transaction> _allTransactions = _mockTransactions();

  DatePeriod _selectedPeriod = DatePeriod.thisWeek;
  DateRange? _customRange;

  String _selectedTypeFilter = 'All'; // All / Income / Expense
  String _selectedCategoryFilter = 'All';

  void _onPeriodChanged(DatePeriod period, {DateTime? start, DateTime? end}) {
    setState(() {
      _selectedPeriod = period;
      if (period == DatePeriod.custom && start != null && end != null) {
        _customRange = resolveDateRange(
          DatePeriod.custom,
          customStart: start,
          customEnd: end,
        );
      }
    });
  }

  DateRange get _activeRange {
    if (_selectedPeriod == DatePeriod.custom && _customRange != null) {
      return _customRange!;
    }
    return resolveDateRange(_selectedPeriod);
  }

  List<Transaction> get _filteredTransactions {
    final range = _activeRange;

    return _allTransactions.where((t) {
      final inRange = range.contains(t.date);
      final matchesType = _selectedTypeFilter == 'All' ||
          (_selectedTypeFilter == 'Income' &&
              t.type == TransactionType.income) ||
          (_selectedTypeFilter == 'Expense' &&
              t.type == TransactionType.expense);
      final matchesCategory = _selectedCategoryFilter == 'All' ||
          t.category == _selectedCategoryFilter;
      return inRange && matchesType && matchesCategory;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double get _totalIncome => _filteredTransactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpenses => _filteredTransactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  @override
  Widget build(BuildContext context) {
    final transactions = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: const Text(
          'Transaction History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: PeriodSelector(
                selectedPeriod: _selectedPeriod,
                customRange: _customRange,
                onPeriodChanged: _onPeriodChanged,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TransactionSummaryCard(
                totalIncome: _totalIncome,
                totalExpenses: _totalExpenses,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterDropdown(
                      label: 'Type',
                      value: _selectedTypeFilter,
                      options: const ['All', 'Income', 'Expense'],
                      onChanged: (value) {
                        setState(() => _selectedTypeFilter = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterDropdown(
                      label: 'Category',
                      value: _selectedCategoryFilter,
                      options: ['All', ...kTransactionCategories],
                      onChanged: (value) {
                        setState(() => _selectedCategoryFilter = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: transactions.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        return TransactionTile(transaction: transactions[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: AppColors.primaryTeal,
          ),
          SizedBox(height: 12),
          Text(
            'No transactions in this period',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try a different date range or filter.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Sample data so the screen is viewable before Firestore is wired up.
/// TODO(Passang): Remove once real data is connected.
List<Transaction> _mockTransactions() {
  final now = DateTime.now();
  return [
    Transaction(
      id: '1',
      description: 'Part-time job pay',
      amount: 320,
      type: TransactionType.income,
      category: 'Other',
      date: now.subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '2',
      description: 'Grocery shopping',
      amount: 45.50,
      type: TransactionType.expense,
      category: 'Food',
      date: now.subtract(const Duration(days: 1)),
      source: 'csv',
    ),
    Transaction(
      id: '3',
      description: 'Bus pass top-up',
      amount: 25,
      type: TransactionType.expense,
      category: 'Transport',
      date: now.subtract(const Duration(days: 2)),
    ),
    Transaction(
      id: '4',
      description: 'Monthly rent',
      amount: 650,
      type: TransactionType.expense,
      category: 'Rent',
      date: now.subtract(const Duration(days: 5)),
      source: 'csv',
    ),
    Transaction(
      id: '5',
      description: 'Movie night',
      amount: 18,
      type: TransactionType.expense,
      category: 'Entertainment',
      date: now.subtract(const Duration(days: 9)),
    ),
    Transaction(
      id: '6',
      description: 'Textbook purchase',
      amount: 60,
      type: TransactionType.expense,
      category: 'Education/Study',
      date: now.subtract(const Duration(days: 12)),
    ),
    Transaction(
      id: '7',
      description: 'Freelance gig',
      amount: 150,
      type: TransactionType.income,
      category: 'Other',
      date: now.subtract(const Duration(days: 20)),
    ),
    Transaction(
      id: '8',
      description: 'Phone bill',
      amount: 40,
      type: TransactionType.expense,
      category: 'Bills',
      date: now.subtract(const Duration(days: 25)),
      source: 'csv',
    ),
  ];
}
