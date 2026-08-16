import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/savings_goal.dart';
import '../../services/goal_service.dart';
import '../../widgets/goal_progress_card.dart';
import 'add_edit_goal_screen.dart';
import 'goal_detail_screen.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  SavingsGoal _goalFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final rawTargetDate = data['targetDate'];

    return SavingsGoal(
      id: document.id,
      title: data['name']?.toString() ?? 'Savings Goal',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0,
      savedAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0,
      targetDate: rawTargetDate is Timestamp
          ? rawTargetDate.toDate()
          : DateTime.now(),
      icon: data['icon']?.toString() ?? '💰',
    );
  }

  Future<void> _openAddGoal(BuildContext context) async {
    final SavingsGoal? goal = await Navigator.push<SavingsGoal>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditGoalScreen()),
    );

    if (goal == null || !context.mounted) {
      return;
    }

    try {
      await GoalService().createGoal(
        name: goal.title,
        targetAmount: goal.targetAmount,
        targetDate: goal.targetDate,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Savings goal created'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create goal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final GoalService goalService = GoalService();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: const Text(
          'Savings Goals',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _openAddGoal(context);
        },
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Goal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: goalService.getGoals(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load savings goals.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final goals = snapshot.data!.docs.map(_goalFromDocument).toList();

          if (goals.isEmpty) {
            return _EmptyGoalsState(
              onAddGoal: () {
                _openAddGoal(context);
              },
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: goals.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final goal = goals[index];

              return GoalProgressCard(
                goal: goal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GoalDetailScreen(goal: goal),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyGoalsState extends StatelessWidget {
  const _EmptyGoalsState({required this.onAddGoal});

  final VoidCallback onAddGoal;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.savings_outlined,
              size: 64,
              color: AppColors.primaryTeal,
            ),
            const SizedBox(height: 16),
            const Text(
              'No savings goals yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Set a target and start tracking your progress toward it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onAddGoal,
              icon: const Icon(Icons.add, color: AppColors.primaryTeal),
              label: const Text(
                'Create your first goal',
                style: TextStyle(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
