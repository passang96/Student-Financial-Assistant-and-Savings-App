import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/savings_goal.dart';
import '../../services/goal_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/gradient_button.dart';
import 'add_edit_goal_screen.dart';

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key, required this.goal});

  final SavingsGoal goal;

  Future<void> _addContribution(BuildContext context) async {
    String amountText = '';
    String? errorMessage;

    final double? amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Contribution'),
              content: TextFormField(
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  errorText: errorMessage,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  amountText = value;
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(amountText.trim());

                    if (value == null || value <= 0) {
                      setDialogState(() {
                        errorMessage = 'Enter an amount greater than zero';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (amount == null || !context.mounted) {
      return;
    }

    try {
      await GoalService().addContribution(
        goalId: goal.id,
        contribution: amount,
      );

      final snapshot = await GoalService().getGoal(goal.id);

      final data = snapshot.data();

      if (data != null) {
        final current = (data['currentAmount'] as num?)?.toDouble() ?? 0;

        final target =
            (data['targetAmount'] as num?)?.toDouble() ?? goal.targetAmount;

        await NotificationService().checkGoalProgress(
          goalId: goal.id,
          goalName: data['name']?.toString() ?? goal.title,
          currentAmount: current,
          targetAmount: target,
        );
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contribution added'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add contribution: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editGoal(BuildContext context, SavingsGoal currentGoal) async {
    final updated = await Navigator.push<SavingsGoal>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditGoalScreen(existingGoal: currentGoal),
      ),
    );

    if (updated == null || !context.mounted) {
      return;
    }

    try {
      await GoalService().updateGoal(
        goalId: currentGoal.id,
        name: updated.title,
        targetAmount: updated.targetAmount,
        targetDate: updated.targetDate,
      );

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update goal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGoal(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete this goal?'),
          content: Text('Delete "${goal.title}" permanently?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await GoalService().deleteGoal(goal.id);

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final GoalService goalService = GoalService();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: goalService.goals.doc(goal.id).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Goal no longer exists.')),
          );
        }

        final data = snapshot.data!.data()!;

        final currentGoal = SavingsGoal(
          id: snapshot.data!.id,
          title: data['name']?.toString() ?? goal.title,
          targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0,
          savedAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0,
          targetDate: data['targetDate'] is Timestamp
              ? (data['targetDate'] as Timestamp).toDate()
              : goal.targetDate,
          icon: data['icon']?.toString() ?? goal.icon,
        );

        final achieved = currentGoal.isAchieved;

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            title: Text(
              currentGoal.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  _editGoal(context, currentGoal);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  _deleteGoal(context);
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (achieved)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Goal Achieved! 🎉',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              if (achieved) const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      currentGoal.icon,
                      style: const TextStyle(fontSize: 40),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '\$${currentGoal.savedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      'of \$${currentGoal.targetAmount.toStringAsFixed(2)} target',
                    ),

                    const SizedBox(height: 16),

                    LinearProgressIndicator(
                      value: currentGoal.progress,
                      minHeight: 10,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${(currentGoal.progress * 100).toStringAsFixed(1)}% complete',
                    ),

                    const SizedBox(height: 6),

                    Text('Target: ${_formatDate(currentGoal.targetDate)}'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (!achieved)
                GradientButton(
                  label: 'Add Contribution',
                  onPressed: () {
                    _addContribution(context);
                  },
                ),

              const SizedBox(height: 24),

              const Text(
                'Contribution History',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: goalService.getContributions(goal.id),
                builder: (context, contributionSnapshot) {
                  if (!contributionSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = contributionSnapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Text('No contributions yet.');
                  }

                  return Column(
                    children: docs.map((document) {
                      final data = document.data();

                      final amount = (data['amount'] as num?)?.toDouble() ?? 0;

                      final date = data['date'] is Timestamp
                          ? (data['date'] as Timestamp).toDate()
                          : DateTime.now();

                      return ListTile(
                        leading: const Icon(
                          Icons.arrow_upward,
                          color: Colors.green,
                        ),
                        title: Text('+\$${amount.toStringAsFixed(2)}'),
                        trailing: Text(_formatDate(date)),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
