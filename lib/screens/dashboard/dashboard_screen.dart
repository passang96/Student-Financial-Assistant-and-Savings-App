import 'package:flutter/material.dart';
import '../budget/budget_screen.dart';
import '../transactions/add_expense_screen.dart';
import '../transactions/add_income_screen.dart';
import '../transactions/transaction_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userName;
  final double balance;
  final double income;
  final double expenses;
  final double budgetRemaining;
  final double savings;

  const DashboardScreen({
    super.key,
    this.userName = 'User',
    this.balance = 0,
    this.income = 0,
    this.expenses = 0,
    this.budgetRemaining = 0,
    this.savings = 0,
  });

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF22C7C0),
                          Color(0xFF0F9F99),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
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
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hello, $userName! 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Here is your financial overview.',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You have no new notifications',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 29,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172033),
                            ),
                          ),
                        ),
                        Text(
                          'This Month',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int columns;

                        if (constraints.maxWidth >= 950) {
                          columns = 5;
                        } else if (constraints.maxWidth >= 600) {
                          columns = 3;
                        } else {
                          columns = 2;
                        }

                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.35,
                          children: [
                            _FinancialCard(
                              title: 'Balance',
                              amount: balance,
                              icon: Icons.account_balance_wallet_outlined,
                              colour: const Color(0xFF0F9F99),
                              backgroundColour: const Color(0xFFE6FFFC),
                            ),
                            _FinancialCard(
                              title: 'Income',
                              amount: income,
                              icon: Icons.trending_up,
                              colour: Colors.green,
                              backgroundColour: const Color(0xFFECFDF3),
                            ),
                            _FinancialCard(
                              title: 'Expenses',
                              amount: expenses,
                              icon: Icons.trending_down,
                              colour: Colors.red,
                              backgroundColour: const Color(0xFFFFEEEE),
                            ),
                            _FinancialCard(
                              title: 'Budget Remaining',
                              amount: budgetRemaining,
                              icon: Icons.pie_chart_outline,
                              colour: Colors.orange,
                              backgroundColour: const Color(0xFFFFF7ED),
                            ),
                            _FinancialCard(
                              title: 'Savings',
                              amount: savings,
                              icon: Icons.savings_outlined,
                              colour: Colors.blue,
                              backgroundColour: const Color(0xFFEFF6FF),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 26, 16, 12),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _QuickActionButton(
                          title: 'Add Income',
                          icon: Icons.add_circle_outline,
                          colour: Colors.green,
                          onTap: () => _openScreen(
                            context,
                            const AddIncomeScreen(),
                          ),
                        ),
                        _QuickActionButton(
                          title: 'Add Expense',
                          icon: Icons.remove_circle_outline,
                          colour: Colors.red,
                          onTap: () => _openScreen(
                            context,
                            const AddExpenseScreen(),
                          ),
                        ),
                        _QuickActionButton(
                          title: 'Transactions',
                          icon: Icons.receipt_long_outlined,
                          colour: Colors.blue,
                          onTap: () => _openScreen(
                            context,
                            const TransactionHistoryScreen(),
                          ),
                        ),
                        _QuickActionButton(
                          title: 'Budget',
                          icon: Icons.pie_chart_outline,
                          colour: Colors.orange,
                          onTap: () => _openScreen(
                            context,
                            const BudgetScreen(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FFFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.sync,
                            color: Color(0xFF0F766E),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Financial totals are calculated automatically '
                              'from saved transactions.',
                              style: TextStyle(
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color colour;
  final Color backgroundColour;

  const _FinancialCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.colour,
    required this.backgroundColour,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColour,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: colour,
              size: 28,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: colour,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color colour;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.icon,
    required this.colour,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: colour),
        label: Text(
          title,
          style: TextStyle(
            color: colour,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: colour),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}