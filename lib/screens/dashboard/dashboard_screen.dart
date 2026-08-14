import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final String displayName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : 'User';

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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewHeader(),

                      const SizedBox(height: 12),

                      _buildOverviewCards(),

                      const SizedBox(height: 22),

                      _buildTransactionsHeader(),

                      const SizedBox(height: 12),

                      _buildTransaction(
                        icon: Icons.lunch_dining,
                        title: 'Lunch',
                        category: 'Food & Drinks',
                        amount: '-\$12.50',
                        date: 'Today',
                      ),

                      const SizedBox(height: 10),

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

  // =========================================================
  // HEADER
  // =========================================================

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

          const SizedBox(width: 12),

          const Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications, color: Color(0xFF111827), size: 27),

              Positioned(
                right: -5,
                top: -7,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.redAccent,
                  child: Text(
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // OVERVIEW
  // =========================================================

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
          'This Month ▼',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildOverviewCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;

        // Mobile:
        // 2 cards per row.
        //
        // Wider Chrome/Desktop preview:
        // Keep cards small instead of stretching across the screen.
        final bool isWideScreen = availableWidth >= 700;

        final double cardWidth = isWideScreen ? 280 : (availableWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isWideScreen ? WrapAlignment.start : WrapAlignment.center,
          children: [
            SizedBox(
              width: cardWidth,
              height: 125,
              child: const _OverviewCard(
                icon: Icons.account_balance_wallet,
                title: 'Total Balance',
                value: '\$2,500',
                footer: '↑ 12% from last month',
                background: Color(0xFFE1FAF8),
              ),
            ),

            SizedBox(
              width: cardWidth,
              height: 125,
              child: const _OverviewCard(
                icon: Icons.shopping_cart,
                title: 'Expenses',
                value: '\$650',
                footer: '↓ 8% from last month',
                background: Color(0xFFFFEEEE),
              ),
            ),

            SizedBox(
              width: cardWidth,
              height: 125,
              child: const _OverviewCard(
                icon: Icons.savings_outlined,
                title: 'Savings',
                value: '\$1,200',
                footer: '↑ 15% from last month',
                background: Color(0xFFF2E8FF),
              ),
            ),

            SizedBox(
              width: cardWidth,
              height: 125,
              child: const _OverviewCard(
                icon: Icons.payments_outlined,
                title: 'Budget Left',
                value: '\$300',
                footer: '32% of budget',
                background: Color(0xFFFFF7BF),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // TRANSACTIONS
  // =========================================================

  Widget _buildTransactionsHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),

        Text(
          'See All',
          style: TextStyle(color: Color(0xFF2563EB), fontSize: 13),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8FAF5),
            child: Icon(icon, color: const Color(0xFF0E9F99), size: 20),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 2),

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
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(height: 2),

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

  // =========================================================
  // BOTTOM NAVIGATION
  // =========================================================

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF10BFB7),
      unselectedItemColor: const Color(0xFF64748B),

      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),

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

// =============================================================
// OVERVIEW CARD
// =============================================================

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF111827)),

          const SizedBox(height: 4),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          ),

          const SizedBox(height: 2),

          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF10B981), fontSize: 9),
          ),
        ],
      ),
    );
  }
}
