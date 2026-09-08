import 'package:flutter/material.dart';

import '../services/budget_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _budgetService = BudgetService();
  final TextEditingController _overallController = TextEditingController();
  final List<_CategoryBudgetField> _categoryFields = [];

  BudgetStatus? _overallStatus;
  Map<String, BudgetStatus> _categoryStatuses = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  @override
  void dispose() {
    _overallController.dispose();
    for (final field in _categoryFields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBudget() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final month = DateTime.now();
      final budget = await _budgetService.getMonthlyBudget(month);
      final overallStatus = await _budgetService.getOverallStatus(date: month);
      final categoryStatuses = await _budgetService.getCategoryStatuses(
        date: month,
      );

      if (!mounted) {
        return;
      }

      _overallController.text = budget?.overallAmount.toStringAsFixed(2) ?? '';
      _replaceCategoryFields(budget?.categoryBudgets ?? {});
      setState(() {
        _overallStatus = overallStatus;
        _categoryStatuses = categoryStatuses;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _replaceCategoryFields(Map<String, double> budgets) {
    for (final field in _categoryFields) {
      field.dispose();
    }
    _categoryFields
      ..clear()
      ..addAll(
        budgets.entries.map(
          (entry) => _CategoryBudgetField(
            category: entry.key,
            amount: entry.value,
          ),
        ),
      );
  }

  Future<void> _saveBudget() async {
    final overallAmount = double.tryParse(_overallController.text.trim());
    if (overallAmount == null || overallAmount <= 0) {
      _showMessage('Enter an overall budget greater than 0.');
      return;
    }

    final categoryBudgets = <String, double>{};
    for (final field in _categoryFields) {
      final category = field.categoryController.text.trim();
      final amount = double.tryParse(field.amountController.text.trim());
      if (category.isEmpty || amount == null || amount <= 0) {
        _showMessage('Each category needs a name and a budget greater than 0.');
        return;
      }
      categoryBudgets[category] = amount;
    }

    setState(() => _isSaving = true);
    try {
      final month = DateTime.now();
      await _budgetService.saveMonthlyBudget(
        month: month,
        overallAmount: overallAmount,
        categoryBudgets: categoryBudgets,
      );
      await _budgetService.checkCurrentMonth(date: month);
      await _loadBudget();
      if (mounted) {
        _showMessage('Budget saved for ${BudgetService.monthKey(month)}.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Could not save budget: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addCategory() {
    setState(() {
      _categoryFields.add(_CategoryBudgetField());
    });
  }

  void _removeCategory(_CategoryBudgetField field) {
    setState(() {
      _categoryFields.remove(field);
      field.dispose();
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Budget')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudget,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_errorMessage != null) _buildErrorState(),
                  if (_errorMessage == null) ...[
                    Text(
                      'Budget for ${BudgetService.monthKey(DateTime.now())}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildOverallEditor(),
                    const SizedBox(height: 20),
                    _buildStatusSection(),
                    const SizedBox(height: 24),
                    _buildCategoryEditor(),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveBudget,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Saving...' : 'Save Budget'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.lock_outline, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Sign in to manage your budget.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadBudget,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallEditor() {
    return TextField(
      controller: _overallController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Overall monthly budget',
        prefixText: '\$ ',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildStatusSection() {
    final status = _overallStatus;
    if (status == null || status.budget <= 0) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.insights_outlined),
          title: Text('No overall budget saved yet'),
          subtitle: Text('Save a budget to see current spending.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall progress',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (status.percentage / 100).clamp(0, 1)),
            const SizedBox(height: 12),
            Text(_statusLabel(status)),
            const SizedBox(height: 4),
            Text(
              'Projected month-end: \$${status.projectedMonthEnd.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Category budgets', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              onPressed: _addCategory,
              tooltip: 'Add category budget',
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        if (_categoryFields.isEmpty)
          const Text('No category budgets added.')
        else
          ..._categoryFields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildCategoryField(field),
            ),
          ),
        ..._categoryStatuses.entries.map(
          (entry) => _buildCategoryStatus(entry.key, entry.value),
        ),
      ],
    );
  }

  Widget _buildCategoryField(_CategoryBudgetField field) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: field.categoryController,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextField(
            controller: field.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          onPressed: () => _removeCategory(field),
          tooltip: 'Remove category budget',
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  Widget _buildCategoryStatus(String category, BudgetStatus status) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: ListTile(
        title: Text(category),
        subtitle: Text(_statusLabel(status)),
        trailing: Text('${status.percentage.toStringAsFixed(0)}%'),
      ),
    );
  }

  String _statusLabel(BudgetStatus status) {
    final remaining = status.remaining;
    if (status.percentage >= 100) {
      return 'Budget exceeded by \$${(-remaining).toStringAsFixed(2)}';
    }
    if (status.percentage >= 80) {
      return 'Budget warning: \$${remaining.toStringAsFixed(2)} remaining';
    }
    return '\$${remaining.toStringAsFixed(2)} remaining';
  }
}

class _CategoryBudgetField {
  final TextEditingController categoryController;
  final TextEditingController amountController;

  _CategoryBudgetField({String? category, double? amount})
      : categoryController = TextEditingController(text: category ?? ''),
        amountController = TextEditingController(
          text: amount == null ? '' : amount.toStringAsFixed(2),
        );

  void dispose() {
    categoryController.dispose();
    amountController.dispose();
  }
}