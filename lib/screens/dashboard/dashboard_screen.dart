import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/budget_service.dart';
import '../../services/firestore_service.dart';
import '../transactions/transaction_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  double _percentageChange(double current, double previous) {
    if (previous == 0) {
      if (current == 0) {
        return 0;
      }

      return 100;
    }

    return ((current - previous) / previous) * 100;
  }

  String _comparisonText(double current, double previous) {
    final change = _percentageChange(current, previous);

    if (change == 0) {
      return '0.0% from last month';
    }

    if (change > 0) {
      return '↑ ${change.toStringAsFixed(1)}% from last month';
    }

    return '↓ ${change.abs().toStringAsFixed(1)}% from last month';
  }

  double _calculateIncome(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    double total = 0;

    for (final doc in docs) {
      final data = doc.data();

      if (data['type']?.toString() == 'income') {
        total += (data['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    return total;
  }

  double _calculateExpenses(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    double total = 0;

    for (final doc in docs) {
      final data = doc.data();

      if (data['type']?.toString() == 'expense') {
        total += (data['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    return total;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _transactionsForMonth(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    DateTime month,
  ) {
    return docs.where((doc) {
      final data = doc.data();

      final rawDate = data['date'];

      if (rawDate is! Timestamp) {
        return false;
      }

      final date = rawDate.toDate();

      return date.year == month.year && date.month == month.month;
    }).toList();
  }

  String _money(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _transactionDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final transactionDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(transactionDay).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  IconData _transactionIcon(String category, String type) {
    if (type == 'income') {
      return Icons.account_balance_wallet_outlined;
    }

    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;

      case 'transport':
        return Icons.directions_bus;

      case 'rent':
        return Icons.home_outlined;

      case 'bills':
        return Icons.receipt_long_outlined;

      case 'shopping':
        return Icons.shopping_cart;

      case 'education/study':
        return Icons.school_outlined;

      case 'entertainment':
        return Icons.movie_outlined;

      case 'medical':
      case 'health':
        return Icons.medical_services_outlined;

      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final String displayName =
        user?.displayName != null && user!.displayName!.trim().isNotEmpty
        ? user.displayName!.trim()
        : 'User';

    final FirestoreService firestoreService = FirestoreService();

    final BudgetService budgetService = BudgetService();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: firestoreService.getTransactions(),
      builder: (context, transactionSnapshot) {
        if (transactionSnapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load Dashboard.\n\n'
                  '${transactionSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (!transactionSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final allTransactions = transactionSnapshot.data!.docs;

        final now = DateTime.now();

        final currentMonth = DateTime(now.year, now.month);

        final previousMonth = DateTime(now.year, now.month - 1);

        final currentTransactions = _transactionsForMonth(
          allTransactions,
          currentMonth,
        );

        final previousTransactions = _transactionsForMonth(
          allTransactions,
          previousMonth,
        );

        final currentIncome = _calculateIncome(currentTransactions);

        final currentExpenses = _calculateExpenses(currentTransactions);

        final previousIncome = _calculateIncome(previousTransactions);

        final previousExpenses = _calculateExpenses(previousTransactions);

        final currentBalance = currentIncome - currentExpenses;

        final previousBalance = previousIncome - previousExpenses;

        final currentSavings = currentIncome - currentExpenses;

        final previousSavings = previousIncome - previousExpenses;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: budgetService.getCurrentMonthBudget(),
          builder: (context, budgetSnapshot) {
            if (budgetSnapshot.hasError) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                body: Center(
                  child: Text(
                    'Could not load budget information.\n\n'
                    '${budgetSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final budgetData = budgetSnapshot.data?.data() ?? {};

            final double totalBudget =
                (budgetData['totalBudget'] as num?)?.toDouble() ?? 2000;

            final double budgetRemaining = totalBudget - currentExpenses;

            final double visibleBudgetRemaining = budgetRemaining < 0
                ? 0
                : budgetRemaining;

            final double budgetUsed = totalBudget > 0
                ? (currentExpenses / totalBudget) * 100
                : 0;

            final recentTransactions = [...allTransactions];

            recentTransactions.sort((a, b) {
              final aData = a.data();

              final bData = b.data();

              final aDate = aData['date'];

              final bDate = bData['date'];

              if (aDate is! Timestamp || bDate is! Timestamp) {
                return 0;
              }

              return bDate.compareTo(aDate);
            });

            final displayedTransactions = recentTransactions.take(5).toList();

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(displayName),

                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(26),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOverviewHeader(),

                              const SizedBox(height: 12),

                              _buildOverviewCards(
                                currentBalance: currentBalance,
                                previousBalance: previousBalance,
                                income: currentIncome,
                                previousIncome: previousIncome,
                                expenses: currentExpenses,
                                previousExpenses: previousExpenses,
                                savings: currentSavings,
                                previousSavings: previousSavings,
                                budgetRemaining: visibleBudgetRemaining,
                                budgetUsed: budgetUsed,
                                budgetExceeded: budgetRemaining < 0,
                              ),

                              const SizedBox(height: 22),

                              _buildTransactionsHeader(context),

                              const SizedBox(height: 12),

                              if (displayedTransactions.isEmpty)
                                _buildEmptyTransactions()
                              else
                                ...displayedTransactions.map((document) {
                                  final data = document.data();

                                  final String type =
                                      data['type']?.toString() ?? '';

                                  final String category =
                                      data['category']?.toString() ?? 'Other';

                                  final String notes =
                                      data['notes']?.toString().trim() ?? '';

                                  final double amount =
                                      (data['amount'] as num?)?.toDouble() ?? 0;

                                  final rawDate = data['date'];

                                  final DateTime date = rawDate is Timestamp
                                      ? rawDate.toDate()
                                      : DateTime.now();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildTransaction(
                                      icon: _transactionIcon(category, type),
                                      title: notes.isNotEmpty
                                          ? notes
                                          : category,
                                      category: category,
                                      amount:
                                          '${type == 'income' ? '+' : '-'}${_money(amount)}',
                                      date: _transactionDate(date),
                                      isIncome: type == 'income',
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(String displayName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF20C9C3), Color(0xFF0E9F99)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),

                const SizedBox(height: 3),

                Text(
                  'Hello, $displayName! 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.notifications, color: Color(0xFF111827), size: 27),
        ],
      ),
    );
  }

  Widget _buildOverviewHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          'This Month',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildOverviewCards({
    required double currentBalance,
    required double previousBalance,
    required double income,
    required double previousIncome,
    required double expenses,
    required double previousExpenses,
    required double savings,
    required double previousSavings,
    required double budgetRemaining,
    required double budgetUsed,
    required bool budgetExceeded,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;

        final bool isWideScreen = availableWidth >= 700;

        final double cardWidth = isWideScreen ? 280 : (availableWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              height: 125,
              child: _OverviewCard(
                icon: Icons.account_balance_wallet,
                title: 'Total Balance',
                value: _money(currentBalance),
                footer: _comparisonText(currentBalance, previousBalance),
                background: const Color(0xFFE1FAF8),
                footerColor: _comparisonColor(
                  currentBalance,
                  previousBalance,
                  positiveIsGood: true,
                ),
              ),
            ),

            SizedBox(
              width: cardWidth,
              height: 125,
              child: _OverviewCard(
                icon: Icons.payments_outlined,
                title: 'Income',
                value: _money(income),
                footer: _comparisonText(income, previousIncome),
                background: const Color(0xFFE8F8EE),
                footerColor: _comparisonColor(
                  income,
                  previousIncome,
                  positiveIsGood: true,
                ),
              ),
            ),

            SizedBox(
              width: cardWidth,
              height: 125,
              child: _OverviewCard(
                icon: Icons.shopping_cart,
                title: 'Expenses',
                value: _money(expenses),
                footer: _comparisonText(expenses, previousExpenses),
                background: const Color(0xFFFFEEEE),
                footerColor: _comparisonColor(
                  expenses,
                  previousExpenses,
                  positiveIsGood: false,
                ),
              ),
            ),

            SizedBox(
              width: cardWidth,
              height: 125,
              child: _OverviewCard(
                icon: Icons.savings_outlined,
                title: 'Savings',
                value: _money(savings),
                footer: _comparisonText(savings, previousSavings),
                background: const Color(0xFFF2E8FF),
                footerColor: _comparisonColor(
                  savings,
                  previousSavings,
                  positiveIsGood: true,
                ),
              ),
            ),

            SizedBox(
              width: cardWidth,
              height: 125,
              child: _OverviewCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Budget Left',
                value: _money(budgetRemaining),
                footer: budgetExceeded
                    ? 'Budget exceeded'
                    : '${budgetUsed.toStringAsFixed(1)}% of budget used',
                background: const Color(0xFFFFF7BF),
                footerColor: budgetExceeded
                    ? Colors.red
                    : const Color(0xFF10B981),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _comparisonColor(
    double current,
    double previous, {
    required bool positiveIsGood,
  }) {
    if (current == previous) {
      return const Color(0xFF64748B);
    }

    final bool increased = current > previous;

    if (positiveIsGood) {
      return increased ? const Color(0xFF10B981) : Colors.red;
    }

    return increased ? Colors.red : const Color(0xFF10B981);
  }

  Widget _buildTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),

        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransactionHistoryScreen(),
              ),
            );
          },
          child: const Text(
            'See All',
            style: TextStyle(color: Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 38, color: Color(0xFF94A3B8)),
          SizedBox(height: 8),
          Text(
            'No transactions yet',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransaction({
    required IconData icon,
    required String title,
    required String category,
    required String amount,
    required String date,
    required bool isIncome,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isIncome
                ? const Color(0xFFE8F8EE)
                : const Color(0xFFE8FAF5),
            child: Icon(
              icon,
              color: isIncome ? Colors.green : const Color(0xFF0E9F99),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              Text(
                date,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.footer,
    required this.background,
    required this.footerColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final String footer;
  final Color background;
  final Color footerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),

          const SizedBox(height: 4),

          Text(title, style: const TextStyle(fontSize: 12)),

          const SizedBox(height: 2),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 3),

          Text(
            footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: footerColor, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
