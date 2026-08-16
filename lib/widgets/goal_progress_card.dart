import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/savings_goal.dart';

/// Reusable card showing a goal's icon, title, progress bar, and amounts.
/// Used in the Savings Goals list. Tapping it opens the goal detail screen.
class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({super.key, required this.goal, this.onTap});

  final SavingsGoal goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool achieved = goal.isAchieved;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      goal.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          achieved
                              ? 'Goal achieved 🎉'
                              : '${goal.daysRemaining} days left',
                          style: TextStyle(
                            fontSize: 12,
                            color: achieved
                                ? AppColors.primaryTealDark
                                : AppColors.textSecondary,
                            fontWeight: achieved
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (achieved)
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.primaryTeal,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: AppColors.backgroundLight,
                  color: achieved
                      ? AppColors.primaryTealDark
                      : AppColors.primaryTeal,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${goal.savedAmount.toStringAsFixed(0)} saved',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'of \$${goal.targetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
