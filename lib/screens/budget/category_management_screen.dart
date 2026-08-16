import 'package:flutter/material.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Rent', 'isDefault': true},
    {'name': 'Food', 'isDefault': true},
    {'name': 'Transport', 'isDefault': true},
    {'name': 'Bills', 'isDefault': true},
    {'name': 'Shopping', 'isDefault': true},
    {'name': 'Education/Study', 'isDefault': true},
    {'name': 'Entertainment', 'isDefault': true},
    {'name': 'Other', 'isDefault': true},
  ];

  IconData _categoryIcon(String name) {
    switch (name) {
      case 'Rent':
        return Icons.home_outlined;

      case 'Food':
        return Icons.restaurant_outlined;

      case 'Transport':
        return Icons.directions_bus_outlined;

      case 'Bills':
        return Icons.receipt_long_outlined;

      case 'Shopping':
        return Icons.shopping_bag_outlined;

      case 'Education/Study':
        return Icons.school_outlined;

      case 'Entertainment':
        return Icons.movie_outlined;

      default:
        return Icons.category_outlined;
    }
  }

  bool _categoryAlreadyExists(String name, {int? ignoredIndex}) {
    for (int i = 0; i < _categories.length; i++) {
      if (i == ignoredIndex) {
        continue;
      }

      final currentName = _categories[i]['name']
          .toString()
          .trim()
          .toLowerCase();

      if (currentName == name.trim().toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  Future<void> _showCategoryDialog({int? categoryIndex}) async {
    final bool isEditing = categoryIndex != null;

    String categoryName = isEditing
        ? _categories[categoryIndex]['name'].toString()
        : '';

    String? errorMessage;

    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(isEditing ? 'Rename Category' : 'Add Category'),
              content: TextFormField(
                initialValue: categoryName,
                autofocus: true,
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: 'Category name',
                  hintText: 'For example: Health',
                  prefixIcon: const Icon(Icons.category_outlined),
                  errorText: errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  categoryName = value;

                  if (errorMessage != null) {
                    setDialogState(() {
                      errorMessage = null;
                    });
                  }
                },
                onFieldSubmitted: (_) {
                  _validateAndCloseDialog(
                    dialogContext: dialogContext,
                    categoryName: categoryName,
                    categoryIndex: categoryIndex,
                    setDialogState: setDialogState,
                    setError: (message) {
                      errorMessage = message;
                    },
                  );
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
                    final cleanName = categoryName.trim();

                    if (cleanName.isEmpty) {
                      setDialogState(() {
                        errorMessage = 'Please enter a category name';
                      });

                      return;
                    }

                    if (_categoryAlreadyExists(
                      cleanName,
                      ignoredIndex: categoryIndex,
                    )) {
                      setDialogState(() {
                        errorMessage = 'This category already exists';
                      });

                      return;
                    }

                    Navigator.of(dialogContext).pop(cleanName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8B1),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (isEditing) {
        _categories[categoryIndex]['name'] = result;
      } else {
        _categories.add({'name': result, 'isDefault': false});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEditing
              ? 'Category updated successfully'
              : 'Category added successfully',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _validateAndCloseDialog({
    required BuildContext dialogContext,
    required String categoryName,
    required int? categoryIndex,
    required StateSetter setDialogState,
    required void Function(String) setError,
  }) {
    final cleanName = categoryName.trim();

    if (cleanName.isEmpty) {
      setDialogState(() {
        setError('Please enter a category name');
      });

      return;
    }

    if (_categoryAlreadyExists(cleanName, ignoredIndex: categoryIndex)) {
      setDialogState(() {
        setError('This category already exists');
      });

      return;
    }

    Navigator.of(dialogContext).pop(cleanName);
  }

  Future<void> _deleteCategory(int categoryIndex) async {
    final String categoryName = _categories[categoryIndex]['name'].toString();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Delete category?'),
          content: Text('Are you sure you want to delete "$categoryName"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _categories.removeAt(categoryIndex);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Category deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: const Color(0xFF14B8B1),
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCategoryDialog();
        },
        backgroundColor: const Color(0xFF14B8B1),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6FFFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0F766E)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Default categories cannot be changed. '
                      'Custom categories can be renamed or deleted.',
                      style: TextStyle(color: Color(0xFF0F766E)),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_categories.length} Categories',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];

                  final bool isDefault = category['isDefault'] as bool;

                  final String name = category['name'].toString();

                  return Card(
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),

                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE6FFFC),
                        child: Icon(
                          _categoryIcon(name),
                          color: const Color(0xFF14B8B1),
                        ),
                      ),

                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: Text(
                        isDefault ? 'Default category' : 'Custom category',
                      ),

                      trailing: isDefault
                          ? const Chip(label: Text('Default'))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Rename',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () {
                                    _showCategoryDialog(categoryIndex: index);
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    _deleteCategory(index);
                                  },
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
