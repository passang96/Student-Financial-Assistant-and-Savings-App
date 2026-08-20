import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/transaction.dart';

const Map<String, IconData> _kCategoryIcons = {
  'Food': Icons.restaurant_outlined,
  'Transport': Icons.directions_bus_outlined,
  'Rent': Icons.home_outlined,
  'Bills': Icons.receipt_long_outlined,
  'Shopping': Icons.shopping_bag_outlined,
  'Education/Study': Icons.school_outlined,
  'Entertainment': Icons.movie_outlined,
  'Other': Icons.category_outlined,
};

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == TransactionType.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              _kCategoryIcons[transaction.category] ?? Icons.category_outlined,
              color: AppColors.primaryTeal,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      transaction.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      _formatDate(transaction.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (transaction.source == 'csv') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CSV',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isIncome ? AppColors.primaryTealDark : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
