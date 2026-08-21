import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/budget_service.dart';
import '../../services/financial_health_service.dart';
import '../../services/firestore_service.dart';
import '../../services/goal_service.dart';
import '../../services/notification_service.dart';
import '../../services/safe_spending_service.dart';
import '../notifications/notifications_screen.dart';
import '../transactions/transaction_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  double _percentageChange(double current, double previous) {
    if (previous == 0) {
      if (current == 0) return 0;
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
      final rawDate = doc.data()['date'];

      if (rawDate is! Timestamp) {
        return false;
      }

      final date = rawDate.toDate();

      return date.year == month.year && date.month == month.month;
    }).toList();
  }

  List<double> _recentDailyExpenseTotals(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    int numberOfDays = 7,
  }) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final Map<String, double> dailyTotals = {};

    for (int i = 0; i < numberOfDays; i++) {
      final date = today.subtract(Duration(days: i));

      final key = '${date.year}-${date.month}-${date.day}';

      dailyTotals[key] = 0;
    }

    for (final doc in docs) {
      final data = doc.data();

      if (data['type']?.toString() != 'expense') {
        continue;
      }

      final rawDate = data['date'];

      if (rawDate is! Timestamp) {
        continue;
      }

      final transactionDate = rawDate.toDate();

      final day = DateTime(
        transactionDate.year,
        transactionDate.month,
        transactionDate.day,
      );

      final difference = today.difference(day).inDays;

      if (difference < 0 || difference >= numberOfDays) {
        continue;
      }

      final key = '${day.year}-${day.month}-${day.day}';

      final amount = (data['amount'] as num?)?.toDouble() ?? 0;

      dailyTotals[key] = (dailyTotals[key] ?? 0) + amount;
    }

    return dailyTotals.values.toList();
  }

  String _money(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _transactionDate(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final transactionDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(transactionDay).inDays;

    if (difference == 0) return 'Today';

    if (difference == 1) return 'Yesterday';

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
      case 'food & drinks':
        return Icons.restaurant;

      case 'transport':
        return Icons.directions_bus;

      case 'rent':
        return Icons.home_outlined;

      case 'bills':
        return Icons.receipt_long_outlined;

      case 'shopping':
        return Icons.shopping_cart;

      case 'education':
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

  Color _comparisonColor(
    double current,
    double previous, {
    required bool positiveIsGood,
  }) {
    if (current == previous) {
      return const Color(0xFF64748B);
    }

    final increased = current > previous;

    if (positiveIsGood) {
      return increased ? const Color(0xFF10B981) : Colors.red;
    }

    return increased ? Colors.red : const Color(0xFF10B981);
  }

  Color _healthColor(int score) {
    if (score >= 90) {
      return const Color(0xFF059669);
    }

    if (score >= 75) {
      return const Color(0xFF10B981);
    }

    if (score >= 60) {
      return Colors.orange;
    }

    if (score >= 40) {
      return const Color(0xFFF97316);
    }

    return Colors.red;
  }

  Color _safeSpendingStatusColor(String status) {
    switch (status) {
      case 'On Track':
        return const Color(0xFF10B981);

      case 'Stay Mindful':
        return Colors.orange;

      case 'Slow Down':
        return const Color(0xFFF97316);

      case 'Pause Spending':
        return Colors.red;

      case 'Set Budget':
        return const Color(0xFF2563EB);

      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _safeSpendingStatusIcon(String status) {
    switch (status) {
      case 'On Track':
        return Icons.check_circle_outline;

      case 'Stay Mindful':
        return Icons.visibility_outlined;

      case 'Slow Down':
        return Icons.warning_amber_rounded;

      case 'Pause Spending':
        return Icons.pause_circle_outline;

      case 'Set Budget':
        return Icons.account_balance_wallet_outlined;

      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final String displayName =
        user?.displayName != null && user!.displayName!.trim().isNotEmpty
        ? user.displayName!.trim()
        : 'User';

    final firestoreService = FirestoreService();

    final budgetService = BudgetService();

    final goalService = GoalService();

    final financialHealthService = FinancialHealthService();

    final safeSpendingService = SafeSpendingService();

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

        final currentNetBalance = currentIncome - currentExpenses;

        final previousNetBalance = previousIncome - previousExpenses;

        final recentDailyExpenses = _recentDailyExpenseTotals(
          allTransactions,
          numberOfDays: 7,
        );

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: goalService.getGoals(),
          builder: (context, goalSnapshot) {
            if (goalSnapshot.hasError) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load savings goals.\n\n'
                      '${goalSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              );
            }

            if (!goalSnapshot.hasData) {
              return const Scaffold(
                backgroundColor: Color(0xFFF8FAFC),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final savingsGoals = goalSnapshot.data!.docs;

            double totalSavings = 0;

            for (final goal in savingsGoals) {
              final data = goal.data();

              totalSavings += (data['currentAmount'] as num?)?.toDouble() ?? 0;
            }

            final availableFunds = currentNetBalance - totalSavings;

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: budgetService.getCurrentMonthBudget(),
              builder: (context, budgetSnapshot) {
                if (budgetSnapshot.hasError) {
                  return Scaffold(
                    backgroundColor: const Color(0xFFF8FAFC),
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load budget information.\n\n'
                          '${budgetSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  );
                }

                final budgetData = budgetSnapshot.data?.data() ?? {};

                final bool hasBudget =
                    budgetSnapshot.data?.exists == true &&
                    (budgetData['totalBudget'] as num?) != null &&
                    ((budgetData['totalBudget'] as num).toDouble() > 0);

                final double totalBudget = hasBudget
                    ? (budgetData['totalBudget'] as num).toDouble()
                    : 0;

                final healthResult = financialHealthService
                    .calculateHealthScore(
                      income: currentIncome,
                      expenses: currentExpenses,
                      monthlyBudget: totalBudget,
                      totalSavings: totalSavings,
                      savingsGoalCount: savingsGoals.length,
                    );

                final SafeSpendingResult safeSpendingResult;

                if (hasBudget) {
                  safeSpendingResult = safeSpendingService
                      .calculateSafeSpending(
                        income: currentIncome,
                        expenses: currentExpenses,
                        savings: totalSavings,
                        monthlyBudget: totalBudget,
                        recentDailyExpenses: recentDailyExpenses,
                      );
                } else {
                  safeSpendingResult = SafeSpendingResult(
                    safeToSpendToday: 0,
                    availableFunds: availableFunds,
                    remainingBudget: 0,
                    daysRemaining:
                        DateTime(now.year, now.month + 1, 0).day - now.day + 1,
                    recentDailyAverage: recentDailyExpenses.isEmpty
                        ? 0
                        : recentDailyExpenses.reduce((a, b) => a + b) /
                              recentDailyExpenses.length,
                    safetyBufferPercent: 20,
                    status: 'Set Budget',
                    message:
                        'Set a monthly budget to receive a personalised Safe to Spend Today estimate.',
                    reasons: const [
                      'Safe spending needs a spending limit so the app knows how much of your money should remain available for the rest of the month.',
                    ],
                  );
                }

                final recentTransactions = [...allTransactions];

                recentTransactions.sort((a, b) {
                  final aDate = a.data()['date'];

                  final bDate = b.data()['date'];

                  if (aDate is! Timestamp || bDate is! Timestamp) {
                    return 0;
                  }

                  return bDate.compareTo(aDate);
                });

                final displayedTransactions = recentTransactions
                    .take(5)
                    .toList();

                return Scaffold(
                  backgroundColor: const Color(0xFFF8FAFC),
                  body: SafeArea(
                    child: Column(
                      children: [
                        _buildHeader(context, displayName),

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
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                16,
                                18,
                                20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildOverviewHeader(),

                                  const SizedBox(height: 12),

                                  _buildOverviewCards(
                                    context: context,
                                    currentNetBalance: currentNetBalance,
                                    previousNetBalance: previousNetBalance,
                                    income: currentIncome,
                                    previousIncome: previousIncome,
                                    expenses: currentExpenses,
                                    previousExpenses: previousExpenses,
                                    totalSavings: totalSavings,
                                    savingsGoals: savingsGoals,
                                    availableFunds: availableFunds,
                                    currentTransactions: currentTransactions,
                                  ),

                                  const SizedBox(height: 22),

                                  _buildSafeSpendingCard(
                                    context,
                                    safeSpendingResult,
                                    hasBudget: hasBudget,
                                    monthlyBudget: totalBudget,
                                  ),

                                  const SizedBox(height: 22),

                                  _buildFinancialHealthCard(
                                    context,
                                    healthResult,
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
                                          data['category']?.toString() ??
                                          'Other';

                                      final String notes =
                                          data['notes']?.toString().trim() ??
                                          '';

                                      final double amount =
                                          (data['amount'] as num?)
                                              ?.toDouble() ??
                                          0;

                                      final rawDate = data['date'];

                                      final DateTime date = rawDate is Timestamp
                                          ? rawDate.toDate()
                                          : DateTime.now();

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: _buildTransaction(
                                          icon: _transactionIcon(
                                            category,
                                            type,
                                          ),
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
      },
    );
  }

  Widget _buildHeader(BuildContext context, String displayName) {
    final notificationService = NotificationService();

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

          StreamBuilder<int>(
            stream: notificationService.getUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF111827),
                      size: 28,
                    ),

                    if (unreadCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
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
    required BuildContext context,
    required double currentNetBalance,
    required double previousNetBalance,
    required double income,
    required double previousIncome,
    required double expenses,
    required double previousExpenses,
    required double totalSavings,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> savingsGoals,
    required double availableFunds,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
    currentTransactions,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        final isWideScreen = availableWidth >= 700;

        final cardWidth = isWideScreen ? 280.0 : (availableWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              height: 125,
              child: _OverviewCard(
                icon: Icons.account_balance_wallet,
                title: 'Net Balance',
                value: _money(currentNetBalance),
                footer: _comparisonText(currentNetBalance, previousNetBalance),
                background: const Color(0xFFE1FAF8),
                footerColor: _comparisonColor(
                  currentNetBalance,
                  previousNetBalance,
                  positiveIsGood: true,
                ),
                onTap: () {
                  _showNetBalanceBreakdown(
                    context,
                    income: income,
                    expenses: expenses,
                    netBalance: currentNetBalance,
                    previousNetBalance: previousNetBalance,
                    transactions: currentTransactions,
                  );
                },
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
                onTap: () {
                  _showTransactionBreakdown(
                    context,
                    title: 'Income Breakdown',
                    type: 'income',
                    currentAmount: income,
                    previousAmount: previousIncome,
                    transactions: currentTransactions,
                  );
                },
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
                onTap: () {
                  _showTransactionBreakdown(
                    context,
                    title: 'Expense Breakdown',
                    type: 'expense',
                    currentAmount: expenses,
                    previousAmount: previousExpenses,
                    transactions: currentTransactions,
                  );
                },
              ),
            ),

            SizedBox(
              width: cardWidth,
              height: 125,
              child: _OverviewCard(
                icon: Icons.savings_outlined,
                title: 'Savings',
                value: _money(totalSavings),
                footer: savingsGoals.isEmpty
                    ? 'No savings goals yet'
                    : savingsGoals.length == 1
                    ? 'Across 1 savings goal'
                    : 'Across ${savingsGoals.length} savings goals',
                background: const Color(0xFFF2E8FF),
                footerColor: const Color(0xFF7C3AED),
                onTap: () {
                  _showSavingsGoalsBreakdown(
                    context,
                    savingsGoals: savingsGoals,
                    totalSavings: totalSavings,
                  );
                },
              ),
            ),

            SizedBox(
              width: cardWidth,
              height: 125,
              child: _OverviewCard(
                icon: Icons.wallet_outlined,
                title: 'Available Funds',
                value: _money(availableFunds),
                footer: availableFunds >= 0
                    ? 'After expenses & savings'
                    : 'More allocated than available',
                background: const Color(0xFFFFF7BF),
                footerColor: availableFunds >= 0
                    ? const Color(0xFF10B981)
                    : Colors.red,
                onTap: () {
                  _showAvailableFundsBreakdown(
                    context,
                    income: income,
                    expenses: expenses,
                    netBalance: currentNetBalance,
                    savings: totalSavings,
                    availableFunds: availableFunds,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSafeSpendingCard(
    BuildContext context,
    SafeSpendingResult result, {
    required bool hasBudget,
    required double monthlyBudget,
  }) {
    final statusColor = _safeSpendingStatusColor(result.status);

    final statusIcon = _safeSpendingStatusIcon(result.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _showSafeSpendingBreakdown(
            context,
            result,
            hasBudget: hasBudget,
            monthlyBudget: monthlyBudget,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEFFCFB), Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCCFBF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: statusColor,
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Safe to Spend Today',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      hasBudget
                          ? _money(result.safeToSpendToday)
                          : 'Set a budget',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            result.status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialHealthCard(
    BuildContext context,
    FinancialHealthResult result,
  ) {
    final statusColor = _healthColor(result.score);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          _showFinancialHealthBreakdown(context, result);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: result.score / 100,
                      strokeWidth: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: statusColor,
                    ),
                  ),

                  Text(
                    '${result.score}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Health',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '${result.score}/100 • ${result.rating}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      result.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSafeSpendingBreakdown(
    BuildContext context,
    SafeSpendingResult result, {
    required bool hasBudget,
    required double monthlyBudget,
  }) {
    final statusColor = _safeSpendingStatusColor(result.status);

    _showBreakdownSheet(
      context,
      title: 'Safe to Spend Today',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        _breakdownHero(
          label: hasBudget ? 'Recommended spending today' : 'Budget required',
          value: hasBudget ? _money(result.safeToSpendToday) : 'Set a budget',
          subtitle: result.status,
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: statusColor.withValues(alpha: 0.20)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _safeSpendingStatusIcon(result.status),
                color: statusColor,
                size: 21,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(color: Color(0xFF475569), height: 1.4),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        const Text(
          'How It Was Calculated',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        _breakdownRow(
          'Available Funds',
          _money(result.availableFunds),
          result.availableFunds >= 0 ? const Color(0xFF10B981) : Colors.red,
        ),

        _breakdownRow(
          'Monthly Budget',
          hasBudget ? _money(monthlyBudget) : 'Not set',
          null,
        ),

        _breakdownRow(
          'Remaining Budget',
          hasBudget ? _money(result.remainingBudget) : 'Not available',
          null,
        ),

        _breakdownRow('Days Remaining', '${result.daysRemaining}', null),

        _breakdownRow(
          '7-Day Daily Average',
          _money(result.recentDailyAverage),
          null,
        ),

        _breakdownRow(
          'Safety Buffer',
          '${result.safetyBufferPercent.toStringAsFixed(0)}%',
          const Color(0xFF2563EB),
        ),

        if (hasBudget) ...[
          const Divider(height: 28),

          _breakdownRow(
            'Safe to Spend Today',
            _money(result.safeToSpendToday),
            statusColor,
            bold: true,
          ),
        ],

        const SizedBox(height: 22),

        const Text(
          'Why This Amount?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        ...result.reasons.map(
          (reason) => _healthInformationRow(
            icon: Icons.info_outline,
            text: reason,
            iconColor: const Color(0xFF2563EB),
          ),
        ),

        if (hasBudget) ...[
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF0E9F99), size: 21),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'The recommendation uses the lower of your available-funds limit and remaining-budget limit, then keeps a 20% buffer for unexpected costs.',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF64748B)),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Safe to Spend Today is an educational budgeting estimate based on information recorded in the app. It is not professional financial advice.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNetBalanceBreakdown(
    BuildContext context, {
    required double income,
    required double expenses,
    required double netBalance,
    required double previousNetBalance,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> transactions,
  }) {
    _showBreakdownSheet(
      context,
      title: 'Net Balance',
      icon: Icons.account_balance_wallet,
      children: [
        _breakdownHero(
          label: 'Income minus expenses',
          value: _money(netBalance),
          subtitle: _comparisonText(netBalance, previousNetBalance),
        ),

        const SizedBox(height: 18),

        _breakdownRow('Income', _money(income), Colors.green),

        _breakdownRow('Expenses', '-${_money(expenses)}', Colors.red),

        const Divider(height: 26),

        _breakdownRow(
          'Net Balance',
          _money(netBalance),
          const Color(0xFF0E9F99),
          bold: true,
        ),

        const SizedBox(height: 10),

        const Text(
          'Net Balance is the amount remaining after recorded expenses are deducted from recorded income.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.4),
        ),

        const SizedBox(height: 22),

        const Text(
          'Recent activity',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ..._breakdownTransactions(transactions),

        const SizedBox(height: 10),

        _viewAllButton(context),
      ],
    );
  }

  void _showAvailableFundsBreakdown(
    BuildContext context, {
    required double income,
    required double expenses,
    required double netBalance,
    required double savings,
    required double availableFunds,
  }) {
    _showBreakdownSheet(
      context,
      title: 'Available Funds',
      icon: Icons.wallet_outlined,
      children: [
        _breakdownHero(
          label: 'Available after expenses and savings',
          value: _money(availableFunds),
          subtitle: 'Net Balance − Savings',
        ),

        const SizedBox(height: 20),

        _breakdownRow('Income', _money(income), Colors.green),

        _breakdownRow('Expenses', '-${_money(expenses)}', Colors.red),

        const Divider(height: 22),

        _breakdownRow(
          'Net Balance',
          _money(netBalance),
          const Color(0xFF0E9F99),
          bold: true,
        ),

        _breakdownRow(
          'Savings allocated',
          '-${_money(savings)}',
          const Color(0xFF7C3AED),
        ),

        const Divider(height: 22),

        _breakdownRow(
          'Available Funds',
          _money(availableFunds),
          availableFunds >= 0 ? const Color(0xFF10B981) : Colors.red,
          bold: true,
        ),

        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            availableFunds >= 0
                ? 'This is the amount remaining after your recorded expenses and savings allocations.'
                : 'Your savings allocations are currently greater than the money remaining after expenses.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _showTransactionBreakdown(
    BuildContext context, {
    required String title,
    required String type,
    required double currentAmount,
    required double previousAmount,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> transactions,
  }) {
    final filtered = transactions
        .where((doc) => doc.data()['type']?.toString() == type)
        .toList();

    final Map<String, double> categories = {};

    for (final doc in filtered) {
      final data = doc.data();

      final category = data['category']?.toString() ?? 'Other';

      final amount = (data['amount'] as num?)?.toDouble() ?? 0;

      categories[category] = (categories[category] ?? 0) + amount;
    }

    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _showBreakdownSheet(
      context,
      title: title,
      icon: type == 'income'
          ? Icons.payments_outlined
          : Icons.shopping_cart_outlined,
      children: [
        _breakdownHero(
          label: type == 'income' ? 'Income this month' : 'Expenses this month',
          value: _money(currentAmount),
          subtitle: _comparisonText(currentAmount, previousAmount),
        ),

        const SizedBox(height: 20),

        if (sortedCategories.isNotEmpty) ...[
          Text(
            type == 'income' ? 'Income sources' : 'Category breakdown',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          ...sortedCategories.take(5).map((entry) {
            final percentage = currentAmount > 0
                ? (entry.value / currentAmount) * 100
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(entry.key)),

                      Text(
                        _money(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  LinearProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(20),
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: type == 'income'
                        ? Colors.green
                        : const Color(0xFF10BFB7),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
        ],

        Text(
          type == 'income' ? 'Recent income' : 'Recent expenses',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ..._breakdownTransactions(filtered),

        const SizedBox(height: 10),

        _viewAllButton(context),
      ],
    );
  }

  void _showSavingsGoalsBreakdown(
    BuildContext context, {
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> savingsGoals,
    required double totalSavings,
  }) {
    _showBreakdownSheet(
      context,
      title: 'Savings',
      icon: Icons.savings_outlined,
      children: [
        _breakdownHero(
          label: 'Total saved',
          value: _money(totalSavings),
          subtitle: savingsGoals.isEmpty
              ? 'No savings goals created yet'
              : savingsGoals.length == 1
              ? 'Across 1 savings goal'
              : 'Across ${savingsGoals.length} savings goals',
        ),

        const SizedBox(height: 22),

        const Text(
          'Your Savings Goals',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        if (savingsGoals.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.savings_outlined,
                  size: 38,
                  color: Color(0xFF94A3B8),
                ),

                SizedBox(height: 8),

                Text(
                  'No savings goals yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Create a savings goal and add contributions to start tracking your actual savings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          )
        else
          ...savingsGoals.map((goal) {
            final data = goal.data();

            final String name = data['name']?.toString() ?? 'Savings Goal';

            final double currentAmount =
                (data['currentAmount'] as num?)?.toDouble() ?? 0;

            final double targetAmount =
                (data['targetAmount'] as num?)?.toDouble() ?? 0;

            final double progress = targetAmount > 0
                ? currentAmount / targetAmount
                : 0;

            final double percentage = (progress * 100).clamp(0.0, 100.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
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
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${_money(currentAmount)} of ${_money(targetAmount)}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 10),

                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(20),
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 8),

        if (savingsGoals.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2E8FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Saved',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                Text(
                  _money(totalSavings),
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showFinancialHealthBreakdown(
    BuildContext context,
    FinancialHealthResult result,
  ) {
    final healthColor = _healthColor(result.score);

    final potentialColor = _healthColor(result.potentialScore);

    _showBreakdownSheet(
      context,
      title: 'Financial Health',
      icon: Icons.monitor_heart_outlined,
      children: [
        _breakdownHero(
          label: 'Financial Health Score',
          value: '${result.score}/100',
          subtitle: result.rating,
        ),

        const SizedBox(height: 14),

        Text(
          result.message,
          style: const TextStyle(color: Color(0xFF475569), height: 1.5),
        ),

        const SizedBox(height: 24),

        const Text(
          'Score Breakdown',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 6),

        const Text(
          'See exactly where your score comes from.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),

        const SizedBox(height: 14),

        ...result.components.map(
          (component) => _financialHealthComponentCard(component),
        ),

        const SizedBox(height: 22),

        const Text(
          'Why This Score?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        ...result.reasons.map(
          (reason) => _healthInformationRow(
            icon: Icons.info_outline,
            text: reason,
            iconColor: const Color(0xFF2563EB),
          ),
        ),

        const SizedBox(height: 22),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFD97706)),

                  SizedBox(width: 8),

                  Text(
                    'Top Recommendation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                result.topRecommendation,
                style: const TextStyle(color: Color(0xFF78350F), height: 1.45),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        const Text(
          'How to Improve',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 6),

        const Text(
          'Actions based on your current financial data.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),

        const SizedBox(height: 12),

        if (result.recommendations.isEmpty)
          _healthInformationRow(
            icon: Icons.check_circle_outline,
            text:
                'Your current financial indicators look balanced. Continue monitoring your spending, savings and budget.',
            iconColor: const Color(0xFF10B981),
          )
        else
          ...result.recommendations.map(
            (recommendation) => _healthInformationRow(
              icon: Icons.trending_up,
              text: recommendation,
              iconColor: const Color(0xFF10B981),
            ),
          ),

        const SizedBox(height: 22),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF6FF), Color(0xFFF0FDFA)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            children: [
              const Text(
                'Potential Financial Health',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        '${result.score}',
                        style: TextStyle(
                          color: healthColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Text(
                        'Current',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22),
                    child: Icon(Icons.arrow_forward, color: Color(0xFF64748B)),
                  ),

                  Column(
                    children: [
                      Text(
                        '${result.potentialScore}',
                        style: TextStyle(
                          color: potentialColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Text(
                        'Potential',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                result.potentialScore > result.score
                    ? 'Addressing your weaker financial areas could improve your score by approximately ${result.potentialScore - result.score} points.'
                    : 'Your current score is already close to the strongest range based on the available data.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF64748B)),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  'This Financial Health Score is an educational budgeting and financial-wellness indicator generated from information recorded in this app. It is not a credit score or professional financial advice.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _financialHealthComponentCard(FinancialHealthComponent component) {
    final double progress = component.maxScore > 0
        ? component.score / component.maxScore
        : 0;

    Color progressColor;

    if (progress >= 0.8) {
      progressColor = const Color(0xFF10B981);
    } else if (progress >= 0.5) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  component.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              Text(
                '${component.score}/${component.maxScore}',
                style: TextStyle(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 7,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: const Color(0xFFE2E8F0),
            color: progressColor,
          ),

          const SizedBox(height: 9),

          Text(
            component.explanation,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthInformationRow({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF475569), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showBreakdownSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 10, 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE1FAF8),
                          child: Icon(icon, color: const Color(0xFF0E9F99)),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: children,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _breakdownHero({
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(
    String label,
    String value,
    Color? valueColor, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF475569),
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF111827),
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _breakdownTransactions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> transactions,
  ) {
    if (transactions.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No transactions for this month.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      ];
    }

    final sorted = [...transactions];

    sorted.sort((a, b) {
      final aDate = a.data()['date'];

      final bDate = b.data()['date'];

      if (aDate is! Timestamp || bDate is! Timestamp) {
        return 0;
      }

      return bDate.compareTo(aDate);
    });

    return sorted.take(5).map((doc) {
      final data = doc.data();

      final type = data['type']?.toString() ?? '';

      final category = data['category']?.toString() ?? 'Other';

      final notes = data['notes']?.toString().trim() ?? '';

      final amount = (data['amount'] as num?)?.toDouble() ?? 0;

      final rawDate = data['date'];

      final date = rawDate is Timestamp ? rawDate.toDate() : DateTime.now();

      return ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: type == 'income'
              ? const Color(0xFFE8F8EE)
              : const Color(0xFFFFEEEE),
          child: Icon(
            _transactionIcon(category, type),
            size: 18,
            color: type == 'income' ? Colors.green : Colors.red,
          ),
        ),

        title: Text(
          notes.isNotEmpty ? notes : category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Text(
          '$category • ${_transactionDate(date)}',
          style: const TextStyle(fontSize: 11),
        ),

        trailing: Text(
          '${type == 'income' ? '+' : '-'}${_money(amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: type == 'income' ? Colors.green : Colors.red,
          ),
        ),
      );
    }).toList();
  }

  Widget _viewAllButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pop(context);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
          );
        },
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('View All Transactions'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0E9F99),
          side: const BorderSide(color: Color(0xFF10BFB7)),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
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
    required this.onTap,
  });

  final IconData icon;

  final String title;

  final String value;

  final String footer;

  final Color background;

  final Color footerColor;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),

                  const SizedBox(width: 4),

                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(title, style: const TextStyle(fontSize: 12)),

              const SizedBox(height: 2),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
        ),
      ),
    );
  }
}
