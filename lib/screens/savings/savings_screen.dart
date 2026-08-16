import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/savings_goal.dart';
import '../../widgets/goal_progress_card.dart';
import 'add_edit_goal_screen.dart';
import 'goal_detail_screen.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  // TODO(Passang): Replace this in-memory list with a Firestore stream
  // (e.g. StreamBuilder on the user's `goals` collection) so goals persist
  // and sync in real time.
  final List<SavingsGoal> _goals = [
    SavingsGoal(
      id: '1',
      title: 'New Laptop',
      targetAmount: 1200,
      savedAmount: 780,
      targetDate: DateTime.now().add(const Duration(days: 45)),
      icon: '💻',
    ),
    SavingsGoal(
      id: '2',
      title: 'Emergency Fund',
      targetAmount: 500,
      savedAmount: 500,
      targetDate: DateTime.now().subtract(const Duration(days: 3)),
      icon: '🛟',
    ),
    SavingsGoal(
      id: '3',
      title: 'Spring Break Trip',
      targetAmount: 800,
      savedAmount: 150,
      targetDate: DateTime.now().add(const Duration(days: 90)),
      icon: '✈️',
    ),
  ];

  Future<void> _openAddGoal() async {
    final SavingsGoal? newGoal = await Navigator.of(context).push<SavingsGoal>(
      MaterialPageRoute(builder: (_) => const AddEditGoalScreen()),
    );

    if (newGoal != null) {
      setState(() => _goals.add(newGoal));
    }
  }

  Future<void> _openGoalDetail(SavingsGoal goal) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GoalDetailScreen(goal: goal)),
    );

    if (result == null) return;

    setState(() {
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index == -1) return;

      if (result is SavingsGoal) {
        // Updated (edited or contribution added).
        _goals[index] = result;
      } else if (result == 'deleted') {
        _goals.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        onPressed: _openAddGoal,
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Goal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _goals.isEmpty
            ? _EmptyGoalsState(onAddGoal: _openAddGoal)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: _goals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  return GoalProgressCard(
                    goal: goal,
                    onTap: () => _openGoalDetail(goal),
                  );
                },
              ),
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
