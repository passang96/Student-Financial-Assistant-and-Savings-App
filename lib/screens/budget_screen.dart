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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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

    _categoryFields.clear();

    for (final entry in budgets.entries) {
      _categoryFields.add(
        _CategoryBudgetField(category: entry.key, amount: entry.value),
      );
    }
  }

  Future<void> _saveBudget() async {
    FocusScope.of(context).unfocus();

    final overallText = _overallController.text.trim();

    final overallAmount = double.tryParse(overallText);

    if (overallAmount == null ||
        !overallAmount.isFinite ||
        overallAmount <= 0) {
      _showMessage('Enter an overall budget greater than 0.');
      return;
    }

    final categoryBudgets = <String, double>{};

    final categoryNames = <String>{};

    for (final field in _categoryFields) {
      final category = field.categoryController.text.trim();

      final amountText = field.amountController.text.trim();

      final amount = double.tryParse(amountText);

      if (category.isEmpty) {
        _showMessage('Each category needs a name.');
        return;
      }

      if (amount == null || !amount.isFinite || amount <= 0) {
        _showMessage('Each category budget must be greater than 0.');
        return;
      }

      final normalizedCategory = category.toLowerCase();

      if (categoryNames.contains(normalizedCategory)) {
        _showMessage('Duplicate category: $category');
        return;
      }

      categoryNames.add(normalizedCategory);

      categoryBudgets[category] = amount;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    try {
      final month = DateTime.now();

      await _budgetService.saveMonthlyBudget(
        month: month,
        overallAmount: overallAmount,
        categoryBudgets: categoryBudgets,
      );

      await _loadBudget();

      if (!mounted) {
        return;
      }

      _showMessage('Budget saved for ${BudgetService.monthKey(month)}.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage('Could not save budget: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budget'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadBudget,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBudget,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  if (_errorMessage != null)
                    _buildErrorState()
                  else ...[
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
                    const SizedBox(height: 20),
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
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            const Text('Unable to load budget.', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadBudget,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallEditor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Budget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _overallController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Overall monthly budget',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
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

    final progress = (status.percentage / 100).clamp(0.0, 1.0).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress, minHeight: 10),
            const SizedBox(height: 16),
            _buildStatusRow('Budget', status.budget),
            const SizedBox(height: 8),
            _buildStatusRow('Spent', status.spent),
            const SizedBox(height: 8),
            _buildStatusRow('Remaining', status.remaining),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Budget Used'),
                Text(
                  '${status.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 28),
            Text(
              _statusLabel(status),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _statusColor(status),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Projected month-end spending: '
              '\$${status.projectedMonthEnd.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCategoryEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Category Budgets',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: _addCategory,
              tooltip: 'Add category budget',
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Set a separate spending limit for each category.'),
        if (_categoryFields.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('No category budgets added.'),
          )
        else
          ..._categoryFields.map(
            (field) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildCategoryField(field),
            ),
          ),
        if (_categoryStatuses.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Category Progress',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._categoryStatuses.entries.map(
            (entry) => _buildCategoryStatus(entry.key, entry.value),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryField(_CategoryBudgetField field) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: field.categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'Example: Food',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: field.amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Budget amount',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeCategory(field),
                  tooltip: 'Remove category',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStatus(String category, BudgetStatus status) {
    final progress = (status.percentage / 100).clamp(0.0, 1.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${status.percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _statusColor(status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 10),
            Text('Budget: \$${status.budget.toStringAsFixed(2)}'),
            Text('Spent: \$${status.spent.toStringAsFixed(2)}'),
            Text(
              _statusLabel(status),
              style: TextStyle(color: _statusColor(status)),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(BudgetStatus status) {
    if (status.percentage >= 100) {
      final exceededBy = status.spent - status.budget;

      return 'Budget exceeded by '
          '\$${exceededBy.toStringAsFixed(2)}';
    }

    if (status.percentage >= 80) {
      return 'Budget warning: '
          '\$${status.remaining.toStringAsFixed(2)} remaining';
    }

    return '\$${status.remaining.toStringAsFixed(2)} remaining';
  }

  Color _statusColor(BudgetStatus status) {
    if (status.percentage >= 100) {
      return Colors.red;
    }

    if (status.percentage >= 80) {
      return Colors.orange;
    }

    return Colors.green;
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
