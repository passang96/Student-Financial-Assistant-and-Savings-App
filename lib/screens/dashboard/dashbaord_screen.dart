


import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewHeader(),
                      const SizedBox(height: 24),
                      _buildOverviewCards(),
                      const SizedBox(height: 26),
                      _buildTransactionsHeader(),
                      const SizedBox(height: 12),
                      _buildTransaction(
                        icon: Icons.lunch_dining,
                        title: 'Lunch',
                        category: 'Food & Drinks',
                        amount: '-\$12.50',
                        date: 'Today',
                      ),
                      const SizedBox(height: 12),
                      _buildTransaction(
                        icon: Icons.directions_bus,
                        title: 'Bus Fare',
                        category: 'Transport',
                        amount: '-\$2.00',
                        date: 'Yesterday',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF20C9C3),
            Color(0xFF0E9F99),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Hello, Kapil! 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications,
                color: Color(0xFF111827),
                size: 30,
              ),
              Positioned(
                right: -5,
                top: -7,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: Colors.redAccent,
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
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
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          'This Month ▼',
          style: TextStyle(
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      childAspectRatio: 1.2,
      children: const [
        _OverviewCard(
          icon: Icons.account_balance_wallet,
          title: 'Total Balance',
          value: '\$2,500',
          footer: '↑ 12% from last month',
          background: Color(0xFFE1FAF8),
        ),
        _OverviewCard(
          icon: Icons.shopping_cart,
          title: 'Expenses',
          value: '\$650',
          footer: '↓ 8% from last month',
          background: Color(0xFFFFEEEE),
        ),
        _OverviewCard(
          icon: Icons.savings_outlined,
          title: 'Savings',
          value: '\$1,200',
          footer: '↑ 15% from last month',
          background: Color(0xFFF2E8FF),
        ),
        _OverviewCard(
          icon: Icons.payments_outlined,
          title: 'Budget Left',
          value: '\$300',
          footer: '32% of budget',
          background: Color(0xFFFFF7BF),
        ),
      ],
    );
  }

  Widget _buildTransactionsHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          'See All',
          style: TextStyle(
            color: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  Widget _buildTransaction({
    required IconData icon,
    required String title,
    required String category,
    required String amount,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8FAF5),
            child: Icon(
              icon,
              color: const Color(0xFF0E9F99),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF10BFB7),
      unselectedItemColor: const Color(0xFF64748B),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Expense',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.savings_outlined),
          label: 'Budget',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          label: 'Reports',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
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
  });

  final IconData icon;
  final String title;
  final String value;
  final String footer;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(height: 6),
          Text(title),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            footer,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}