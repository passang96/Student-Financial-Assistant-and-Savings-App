import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/savings_goal.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

const List<String> _goalIcons = [
  '💰',
  '💻',
  '✈️',
  '🛟',
  '🎓',
  '🏠',
  '🚗',
  '🎁',
];

class AddEditGoalScreen extends StatefulWidget {
  const AddEditGoalScreen({super.key, this.existingGoal});

  final SavingsGoal? existingGoal;

  bool get isEditing => existingGoal != null;

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;

  late final TextEditingController _amountController;

  late DateTime _targetDate;
  late String _selectedIcon;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingGoal;

    _titleController = TextEditingController(text: existing?.title ?? '');

    _amountController = TextEditingController(
      text: existing != null ? existing.targetAmount.toStringAsFixed(0) : '',
    );

    _targetDate =
        existing?.targetDate ?? DateTime.now().add(const Duration(days: 30));

    _selectedIcon = existing?.icon ?? _goalIcons.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final goal = SavingsGoal(
      id: widget.existingGoal?.id ?? '',
      title: _titleController.text.trim(),
      targetAmount: double.parse(_amountController.text.trim()),
      targetDate: _targetDate,
      savedAmount: widget.existingGoal?.savedAmount ?? 0,
      contributions: widget.existingGoal?.contributions ?? const [],
      icon: _selectedIcon,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    Navigator.of(context).pop(goal);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: Text(
          widget.isEditing ? 'Edit Goal' : 'New Savings Goal',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose an icon',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _goalIcons.map((icon) {
                    final selected = icon == _selectedIcon;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = icon;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryTeal.withValues(alpha: 0.15)
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryTeal
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 20)),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),

                CustomTextField(
                  label: 'Goal Name',
                  hint: 'e.g. New Laptop',
                  icon: Icons.flag_outlined,
                  controller: _titleController,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Give your goal a name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                CustomTextField(
                  label: 'Target Amount',
                  hint: 'e.g. 500',
                  icon: Icons.attach_money,
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a target amount';
                    }

                    final parsed = double.tryParse(value.trim());

                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount greater than 0';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Target Date',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.primaryTeal,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(_targetDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                GradientButton(
                  label: widget.isEditing ? 'Save Changes' : 'Create Goal',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
