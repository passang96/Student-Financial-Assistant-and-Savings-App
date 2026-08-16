import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'budget/budget_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'reports/reports_screen.dart';
import 'transactions/transaction_history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const DashboardScreen();

      case 1:
        return const TransactionHistoryScreen();

      case 2:
        return const BudgetScreen();

      case 3:
        return const ReportsScreen();

      case 4:
        return const ProfileScreen();

      default:
        return const DashboardScreen();
    }
  }

  Future<void> _handleBackButton() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });

      return;
    }

    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        _handleBackButton();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _getCurrentScreen(),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.receipt_long_outlined,
                  selectedIcon: Icons.receipt_long,
                  label: 'Expense',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.savings_outlined,
                  selectedIcon: Icons.savings,
                  label: 'Budget',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.analytics_outlined,
                  selectedIcon: Icons.analytics,
                  label: 'Reports',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final bool selected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _changePage(index);
        },
        child: Container(
          height: 72,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                size: 25,
                color: selected
                    ? const Color(0xFF10BFB7)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? const Color(0xFF10BFB7)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: selected ? 22 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF10BFB7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
