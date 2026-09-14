import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/budget_service.dart';
import '../../services/category_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import 'category_management_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _budgetService = BudgetService();
  final FirestoreService _firestoreService = FirestoreService();
  final CategoryService _categoryService = CategoryService();
  final NotificationService _notificationService = NotificationService();

  /// Prevents the same notification check from running repeatedly
  /// while this screen is rebuilding.
  final Set<String> _checkedNotificationStates = {};

  /// These are only used to provide the standard category names.
  /// They are NOT used as automatic budget amounts.
  final List<String> _defaultCategories = [
    'Rent',
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Education/Study',
    'Entertainment',
    'Other',
  ];

  final Map<String, IconData> _defaultIcons = {
    'Rent': Icons.home_outlined,
    'Food': Icons.restaurant,
    'Transport': Icons.directions_bus,
    'Bills': Icons.receipt_long_outlined,
    'Shopping': Icons.shopping_cart,
    'Education/Study': Icons.school_outlined,
    'Entertainment': Icons.movie_outlined,
    'Other': Icons.category_outlined,
  };

  Future<void> _editMonthlyBudget(double currentBudget) async {
    String budgetText = currentBudget > 0
        ? currentBudget.toStringAsFixed(0)
        : '';

    String? errorMessage;

    final double? newBudget = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                currentBudget > 0
                    ? 'Edit Monthly Budget'
                    : 'Set Monthly Budget',
              ),
              content: TextFormField(
                initialValue: budgetText,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Monthly budget',
                  hintText: 'Enter your monthly budget',
                  prefixText: '\$ ',
                  errorText: errorMessage,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  budgetText = value;

                  if (errorMessage != null) {
                    setDialogState(() {
                      errorMessage = null;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(budgetText.trim());

                    if (value == null || value <= 0) {
                      setDialogState(() {
                        errorMessage = 'Enter a budget greater than zero';
                      });

                      return;
                    }

                    Navigator.of(dialogContext).pop(value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8B1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || newBudget == null) {
      return;
    }

    try {
      await _budgetService.saveMonthlyBudget(totalBudget: newBudget);

      /// Allow notification checks again because
      /// the budget limit has changed.
      _checkedNotificationStates.clear();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentBudget > 0
                ? 'Monthly budget updated'
                : 'Monthly budget set successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update budget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editCategoryBudget({
    required String category,
    required double currentLimit,
  }) async {
    String limitText = currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '';

    String? errorMessage;

    final double? newLimit = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                currentLimit > 0
                    ? 'Edit $category Budget'
                    : 'Set $category Budget',
              ),
              content: TextFormField(
                initialValue: limitText,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '$category monthly limit',
                  hintText: 'Enter category limit',
                  prefixText: '\$ ',
                  errorText: errorMessage,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  limitText = value;

                  if (errorMessage != null) {
                    setDialogState(() {
                      errorMessage = null;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = double.tryParse(limitText.trim());

                    if (value == null || value < 0) {
                      setDialogState(() {
                        errorMessage = 'Enter a valid budget limit';
                      });

                      return;
                    }

                    Navigator.of(dialogContext).pop(value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8B1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || newLimit == null) {
      return;
    }

    try {
      await _budgetService.saveCategoryBudget(
        category: category,
        limit: newLimit,
      );

      /// Budget changed, so we allow a fresh
      /// threshold check for this category.
      _checkedNotificationStates.removeWhere(
        (key) => key.startsWith('$category|'),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newLimit > 0
                ? '$category budget updated'
                : '$category budget cleared',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update category budget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, double> _calculateCategorySpending(
    QuerySnapshot<Map<String, dynamic>> transactionSnapshot,
  ) {
    final Map<String, double> spending = {};

    for (final document in transactionSnapshot.docs) {
      final data = document.data();

      if (data['type']?.toString() != 'expense') {
        continue;
      }

      final category = data['category']?.toString() ?? 'Other';

      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

      spending[category] = (spending[category] ?? 0) + amount;
    }

    return spending;
  }

  double _calculateTotalSpent(Map<String, double> categorySpending) {
    return categorySpending.values.fold(0.0, (total, amount) => total + amount);
  }

  List<String> _buildCategoryList(
    QuerySnapshot<Map<String, dynamic>>? categorySnapshot,
    Map<String, double> categoryBudgets,
    Map<String, double> categorySpending,
  ) {
    final Set<String> categories = {
      ..._defaultCategories,
      ...categoryBudgets.keys,
      ...categorySpending.keys,
    };

    if (categorySnapshot != null) {
      for (final document in categorySnapshot.docs) {
        final data = document.data();

        if (data['type'] != 'expense') {
          continue;
        }

        final name = data['name']?.toString().trim();

        if (name != null && name.isNotEmpty) {
          categories.add(name);
        }
      }
    }

    final list = categories.toList();

    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return list;
  }

  IconData _categoryIcon(String category) {
    return _defaultIcons[category] ?? Icons.category_outlined;
  }

  double _safeProgress(double spent, double limit) {
    if (limit <= 0) {
      return 0;
    }

    final progress = spent / limit;

    if (progress > 1) {
      return 1;
    }

    if (progress < 0) {
      return 0;
    }

    return progress;
  }

  void _scheduleNotificationChecks({
    required double totalBudget,
    required double totalSpent,
    required Map<String, double> categoryBudgets,
    required Map<String, double> categorySpending,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBudgetNotifications(
        totalBudget: totalBudget,
        totalSpent: totalSpent,
        categoryBudgets: categoryBudgets,
        categorySpending: categorySpending,
      );
    });
  }

  Future<void> _checkBudgetNotifications({
    required double totalBudget,
    required double totalSpent,
    required Map<String, double> categoryBudgets,
    required Map<String, double> categorySpending,
  }) async {
    /// Overall monthly budget notification.
    if (totalBudget > 0) {
      final monthlyPercentage = (totalSpent / totalBudget) * 100;

      String monthlyState = 'safe';

      if (monthlyPercentage >= 100) {
        monthlyState = 'exceeded';
      } else if (monthlyPercentage >= 80) {
        monthlyState = 'warning';
      }

      if (monthlyState != 'safe') {
        final stateKey = 'Monthly Budget|$monthlyState';

        if (!_checkedNotificationStates.contains(stateKey)) {
          _checkedNotificationStates.add(stateKey);

          try {
            await _notificationService.checkBudget(
              budgetId: 'monthly_budget',
              category: 'Monthly',
              budgetAmount: totalBudget,
              spentAmount: totalSpent,
            );
          } catch (e) {
            debugPrint('Monthly budget notification error: $e');
          }
        }
      }
    }

    /// Category notifications.
    for (final entry in categoryBudgets.entries) {
      final category = entry.key;
      final limit = entry.value;

      if (limit <= 0) {
        continue;
      }

      final spent = categorySpending[category] ?? 0;

      final percentage = (spent / limit) * 100;

      String state = 'safe';

      if (percentage >= 100) {
        state = 'exceeded';
      } else if (percentage >= 80) {
        state = 'warning';
      }

      if (state == 'safe') {
        continue;
      }

      final stateKey = '$category|$state';

      if (_checkedNotificationStates.contains(stateKey)) {
        continue;
      }

      _checkedNotificationStates.add(stateKey);

      try {
        await _notificationService.checkBudget(
          budgetId: category.toLowerCase().replaceAll(' ', '_'),
          category: category,
          budgetAmount: limit,
          spentAmount: spent,
        );
      } catch (e) {
        debugPrint('$category budget notification error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _budgetService.getCurrentMonthBudget(),
      builder: (context, budgetSnapshot) {
        if (budgetSnapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load budget.\n'
                  '${budgetSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (budgetSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAFC),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final budgetData = budgetSnapshot.data?.data() ?? {};

        final double totalBudget =
            (budgetData['totalBudget'] as num?)?.toDouble() ?? 0.0;

        final bool hasMonthlyBudget = totalBudget > 0;

        final Map<String, double> categoryBudgets = {};

        final dynamic rawCategoryBudgets = budgetData['categoryBudgets'];

        if (rawCategoryBudgets is Map) {
          rawCategoryBudgets.forEach((key, value) {
            if (value is num) {
              categoryBudgets[key.toString()] = value.toDouble();
            }
          });
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestoreService.getCurrentMonthTransactions(),
          builder: (context, transactionSnapshot) {
            if (transactionSnapshot.hasError) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load transactions.\n'
                      '${transactionSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            if (!transactionSnapshot.hasData) {
              return const Scaffold(
                backgroundColor: Color(0xFFF8FAFC),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final categorySpending = _calculateCategorySpending(
              transactionSnapshot.data!,
            );

            final totalSpent = _calculateTotalSpent(categorySpending);

            final remaining = totalBudget - totalSpent;

            final budgetProgress = _safeProgress(totalSpent, totalBudget);

            /// Notifications are only checked when
            /// the user has actually configured a
            /// monthly/category budget.
            _scheduleNotificationChecks(
              totalBudget: totalBudget,
              totalSpent: totalSpent,
              categoryBudgets: categoryBudgets,
              categorySpending: categorySpending,
            );

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _categoryService.getCategories(),
              builder: (context, categorySnapshot) {
                if (categorySnapshot.hasError) {
                  return Scaffold(
                    backgroundColor: const Color(0xFFF8FAFC),
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load categories.\n'
                          '${categorySnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }

                final categories = _buildCategoryList(
                  categorySnapshot.data,
                  categoryBudgets,
                  categorySpending,
                );

                return Scaffold(
                  backgroundColor: const Color(0xFFF8FAFC),
                  body: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(),

                          Transform.translate(
                            offset: const Offset(0, -18),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                30,
                                28,
                                20,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(34),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasMonthlyBudget)
                                    _monthlyBudgetCard(
                                      totalBudget: totalBudget,
                                      spent: totalSpent,
                                      remaining: remaining,
                                      progress: budgetProgress,
                                      onEdit: () {
                                        _editMonthlyBudget(totalBudget);
                                      },
                                    )
                                  else
                                    _noMonthlyBudgetCard(
                                      totalSpent: totalSpent,
                                      onSetBudget: () {
                                        _editMonthlyBudget(0);
                                      },
                                    ),

                                  const SizedBox(height: 30),

                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Budget Categories',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF171B2E),
                                          ),
                                        ),
                                      ),

                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CategoryManagementScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.settings_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('Manage'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF14B8B1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  if (!hasMonthlyBudget)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDFA),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFF99F6E4),
                                        ),
                                      ),
                                      child: const Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 20,
                                            color: Color(0xFF0F766E),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Set your monthly budget and category limits based on your own financial situation.',
                                              style: TextStyle(
                                                fontSize: 13,
                                                height: 1.4,
                                                color: Color(0xFF0F766E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  ...categories.map((category) {
                                    final spent =
                                        categorySpending[category] ?? 0;

                                    final limit =
                                        categoryBudgets[category] ?? 0;

                                    return BudgetCategoryCard(
                                      icon: _categoryIcon(category),
                                      title: category,
                                      spent: spent,
                                      limit: limit,
                                      progress: _safeProgress(spent, limit),
                                      onEdit: () {
                                        _editCategoryBudget(
                                          category: category,
                                          currentLimit: limit,
                                        );
                                      },
                                    );
                                  }),

                                  const SizedBox(height: 25),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 40, 30, 35),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF20C7C5), Color(0xFF10B8A9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 58,
              color: Color(0xFF42517A),
            ),
          ),
          SizedBox(height: 20),
          Text('BUDGET', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 4),
          Text(
            'Manage your goals',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noMonthlyBudgetCard({
    required double totalSpent,
    required VoidCallback onSetBudget,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C7C4), Color(0xFF348CF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Monthly Budget',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
            ],
          ),

          const SizedBox(height: 14),

          const Text(
            'No budget set yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            totalSpent > 0
                ? 'You have spent \$${totalSpent.toStringAsFixed(2)} this month. Set a budget to start tracking your spending.'
                : 'Create a monthly spending limit that matches your own financial situation.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSetBudget,
              icon: const Icon(Icons.add),
              label: const Text('Set Monthly Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF178FAE),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyBudgetCard({
    required double totalBudget,
    required double spent,
    required double remaining,
    required double progress,
    required VoidCallback onEdit,
  }) {
    final double visibleRemaining = remaining < 0 ? 0 : remaining;

    final bool exceeded = remaining < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C7C4), Color(0xFF348CF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Monthly Budget',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit monthly budget',
              ),
            ],
          ),

          Text(
            '\$${totalBudget.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${spent.toStringAsFixed(2)} spent',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                exceeded
                    ? '\$${(-remaining).toStringAsFixed(2)} over'
                    : '\$${visibleRemaining.toStringAsFixed(2)} left',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0x66FFFFFF),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              totalBudget <= 0
                  ? '0%'
                  : '${((spent / totalBudget) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetCategoryCard extends StatelessWidget {
  const BudgetCategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.spent,
    required this.limit,
    required this.progress,
    required this.onEdit,
  });

  final IconData icon;
  final String title;
  final double spent;
  final double limit;
  final double progress;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final bool hasBudget = limit > 0;

    final double remaining = hasBudget ? limit - spent : 0;

    final bool exceeded = hasBudget && remaining < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 26, color: const Color(0xFF222222)),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              IconButton(
                tooltip: hasBudget ? 'Edit budget limit' : 'Set budget limit',
                onPressed: onEdit,
                icon: Icon(
                  hasBudget ? Icons.edit_outlined : Icons.add_circle_outline,
                  size: 20,
                  color: const Color(0xFF14B8B1),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: Text(
                  '\$${spent.toStringAsFixed(2)} spent',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5F6875),
                  ),
                ),
              ),
              Text(
                hasBudget
                    ? 'Limit \$${limit.toStringAsFixed(2)}'
                    : 'No budget set',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasBudget
                      ? const Color(0xFF222222)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: hasBudget ? progress : 0,
              minHeight: 7,
              backgroundColor: const Color(0xFFE1E5EA),
              valueColor: AlwaysStoppedAnimation<Color>(
                exceeded ? Colors.red : const Color(0xFF20C7C5),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              !hasBudget
                  ? 'Set a budget to track this category'
                  : exceeded
                  ? '\$${(-remaining).toStringAsFixed(2)} over budget'
                  : '\$${remaining.toStringAsFixed(2)} remaining',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: exceeded ? Colors.red : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
