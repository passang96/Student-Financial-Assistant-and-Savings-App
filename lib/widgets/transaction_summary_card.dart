import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Shows Total Income, Total Expenses, and Balance for the currently
/// selected period. Recalculated whenever the period/filters change.
class TransactionSummaryCard extends StatelessWidget {
  const TransactionSummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
  });

  final double totalIncome;
  final double totalExpenses;

  double get balance => totalIncome - totalExpenses;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _AmountBlock(
                label: 'Income',
                amount: totalIncome,
                color: AppColors.primaryTealDark,
                icon: Icons.arrow_downward_rounded,
              ),
              Container(width: 1, height: 40, color: AppColors.backgroundLight),
              _AmountBlock(
                label: 'Expenses',
                amount: totalExpenses,
                color: AppColors.error,
                icon: Icons.arrow_upward_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Balance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${balance < 0 ? '-' : ''}\$${balance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: balance < 0 ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
