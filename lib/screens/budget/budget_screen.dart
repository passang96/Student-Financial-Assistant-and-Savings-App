import 'package:flutter/material.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(30, 40, 30, 35),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF20C7C5),
                            Color(0xFF10B8A9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Center(
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 58,
                              color: Color(0xFF42517A),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'BUDGET',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage your goals',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Transform.translate(
                      offset: const Offset(0, -18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(28, 30, 28, 20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(34),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _monthlyBudgetCard(),

                            const SizedBox(height: 30),

                            const Text(
                              'Budget Categories',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF171B2E),
                              ),
                            ),

                            const SizedBox(height: 16),

                            const BudgetCategoryCard(
                              icon: Icons.restaurant,
                              title: 'Food',
                              amount: '\$420 / \$600',
                              progress: 0.70,
                            ),

                            const BudgetCategoryCard(
                              icon: Icons.directions_bus,
                              title: 'Transport',
                              amount: '\$180 / \$400',
                              progress: 0.45,
                            ),

                            const BudgetCategoryCard(
                              icon: Icons.shopping_cart,
                              title: 'Shopping',
                              amount: '\$250 / \$500',
                              progress: 0.50,
                            ),

                            const SizedBox(height: 10),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE1E4E8),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        'Savings Goal\nLaptop Fund',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '\$850 / \$1500',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: const LinearProgressIndicator(
                                      value: 0.57,
                                      minHeight: 8,
                                      backgroundColor: Color(0xFFE1E5EA),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Color(0xFF20C7C5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            BottomNavigationBar(
              currentIndex: 2,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF16BFB4),
              unselectedItemColor: const Color(0xFF6D7480),
              onTap: (index) {
                if (index == 0) {
                  Navigator.pop(context);
                } else if (index != 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This page will be available soon.'),
                    ),
                  );
                }
              },
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
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Budget',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined),
                  label: 'Reports',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthlyBudgetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF22C7C4),
            Color(0xFF348CF5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Budget',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '\$2,000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '\$1,200 spent',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '\$800 left',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.60,
              minHeight: 8,
              backgroundColor: Color(0x66FFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '60%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final double progress;

  const BudgetCategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 26,
            color: const Color(0xFF222222),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5F6875),
            ),
          ),

          const SizedBox(width: 14),

          SizedBox(
            width: 110,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: const Color(0xFFE1E5EA),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF20C7C5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}