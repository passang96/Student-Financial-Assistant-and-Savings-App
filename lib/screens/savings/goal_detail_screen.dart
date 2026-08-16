import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/savings_goal.dart';
import '../../widgets/gradient_button.dart';
import 'add_edit_goal_screen.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key, required this.goal});

  final SavingsGoal goal;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late SavingsGoal _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  Future<void> _addContribution() async {
    final controller = TextEditingController();
    final amount = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Contribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: AppColors.primaryTeal,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Add',
                  onPressed: () {
                    final value = double.tryParse(controller.text.trim());
                    if (value != null && value > 0) {
                      Navigator.of(context).pop(value);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (amount == null) return;

    // TODO(Passang): Write this contribution to Firestore (append to the
    // goal's contributions subcollection and increment savedAmount there),
    // then this local update can be replaced by a stream listener.
    setState(() {
      _goal = _goal.copyWith(
        savedAmount: _goal.savedAmount + amount,
        contributions: [
          ..._goal.contributions,
          GoalContribution(amount: amount, date: DateTime.now()),
        ],
      );
    });
  }

  Future<void> _editGoal() async {
    final updated = await Navigator.of(context).push<SavingsGoal>(
      MaterialPageRoute(
        builder: (_) => AddEditGoalScreen(existingGoal: _goal),
      ),
    );
    if (updated != null) {
      setState(() => _goal = updated);
    }
  }

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete this goal?'),
          content: Text(
            'This will permanently remove "${_goal.title}" and its contribution history.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // TODO(Passang): Delete the goal document (and its contributions
      // subcollection) from Firestore here.
      Navigator.of(context).pop('deleted');
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool achieved = _goal.isAchieved;

    return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    Navigator.of(context).pop(_goal);
  },
  child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          title: Text(
            _goal.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_goal),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editGoal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _deleteGoal,
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (achieved) const _GoalAchievedBanner(),
              if (achieved) const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        _goal.icon,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '\$${_goal.savedAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'of \$${_goal.targetAmount.toStringAsFixed(0)} target',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _goal.progress,
                        minHeight: 10,
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
                          '${(_goal.progress * 100).toStringAsFixed(0)}% complete',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          achieved
                              ? 'Goal reached!'
                              : 'Target: ${_formatDate(_goal.targetDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!achieved) ...[
                GradientButton(
                  label: 'Add Contribution',
                  onPressed: _addContribution,
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Contribution History',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (_goal.contributions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No contributions yet. Add one to get started.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...List.generate(_goal.contributions.length, (index) {
                  final c = _goal.contributions[
                      _goal.contributions.length - 1 - index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          color: AppColors.primaryTeal,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '+\$${c.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(c.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Celebratory banner shown at the top of the goal detail screen once the
/// savings target has been reached.
class _GoalAchievedBanner extends StatelessWidget {
  const _GoalAchievedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryTeal, AppColors.primaryTealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
          SizedBox(height: 8),
          Text(
            'Goal Achieved! 🎉',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'You hit your savings target. Nice work!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
