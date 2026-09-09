import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/category_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoryService _categoryService = CategoryService();

  final List<Map<String, dynamic>> _defaultCategories = [
    {'name': 'Rent', 'icon': Icons.home_outlined},
    {'name': 'Food', 'icon': Icons.restaurant_outlined},
    {'name': 'Transport', 'icon': Icons.directions_bus_outlined},
    {'name': 'Bills', 'icon': Icons.receipt_long_outlined},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_outlined},
    {'name': 'Education/Study', 'icon': Icons.school_outlined},
    {'name': 'Entertainment', 'icon': Icons.movie_outlined},
    {'name': 'Other', 'icon': Icons.category_outlined},
  ];

  bool _defaultCategoryExists(String name) {
    final cleanName = name.trim().toLowerCase();

    return _defaultCategories.any(
      (category) => category['name'].toString().toLowerCase() == cleanName,
    );
  }

  bool _customCategoryExists(
    String name,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents, {
    String? ignoredId,
  }) {
    final cleanName = name.trim().toLowerCase();

    for (final document in documents) {
      if (document.id == ignoredId) {
        continue;
      }

      final data = document.data();

      if (data['type']?.toString() != 'expense') {
        continue;
      }

      if (data['name'].toString().trim().toLowerCase() == cleanName) {
        return true;
      }
    }

    return false;
  }

  Future<void> _showAddCategoryDialog(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    String categoryName = '';
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
              title: const Text('Add Category'),
              content: TextFormField(
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
                    final cleanName = categoryName.trim();

                    if (cleanName.isEmpty) {
                      setDialogState(() {
                        errorMessage = 'Please enter a category name';
                      });
                      return;
                    }

                    if (_defaultCategoryExists(cleanName)) {
                      setDialogState(() {
                        errorMessage = 'This default category already exists';
                      });
                      return;
                    }

                    if (_customCategoryExists(cleanName, documents)) {
                      setDialogState(() {
                        errorMessage = 'This category already exists';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, cleanName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8B1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
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

    try {
      await _categoryService.addCategory(name: result, type: 'expense');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _renameCategory({
    required String categoryId,
    required String currentName,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  }) async {
    String categoryName = currentName;
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
              title: const Text('Rename Category'),
              content: TextFormField(
                initialValue: currentName,
                autofocus: true,
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: 'Category name',
                  prefixIcon: const Icon(Icons.edit_outlined),
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
                    final cleanName = categoryName.trim();

                    if (cleanName.isEmpty) {
                      setDialogState(() {
                        errorMessage = 'Please enter a category name';
                      });
                      return;
                    }

                    if (_defaultCategoryExists(cleanName)) {
                      setDialogState(() {
                        errorMessage = 'This default category already exists';
                      });
                      return;
                    }

                    if (_customCategoryExists(
                      cleanName,
                      documents,
                      ignoredId: categoryId,
                    )) {
                      setDialogState(() {
                        errorMessage = 'This category already exists';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, cleanName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8B1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
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

    try {
      await _categoryService.updateCategory(
        categoryId: categoryId,
        newName: result,
        type: 'expense',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCategory({
    required String categoryId,
    required String categoryName,
  }) async {
    // Check first so the user knows if existing transactions will be
    // left pointing at a category that no longer appears in the list.
    int usageCount = 0;

    try {
      usageCount = await _categoryService.countTransactionsUsingCategory(
        categoryName,
      );
    } catch (_) {
      // If the count fails we still let the user proceed with delete;
      // the warning is a courtesy, not a hard requirement.
    }

    if (!mounted) {
      return;
    }

    final String warningText = usageCount > 0
        ? 'Are you sure you want to delete "$categoryName"?\n\n'
              '$usageCount existing transaction'
              '${usageCount == 1 ? '' : 's'} still use this category and '
              'will keep the "$categoryName" label, but it will no longer '
              'appear in dropdowns or reports as an active category.'
        : 'Are you sure you want to delete "$categoryName"?';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Delete category?'),
          content: Text(warningText),
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

    if (confirmed != true) {
      return;
    }

    try {
      await _categoryService.deleteCategory(categoryId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete category: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _categoryService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load categories.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = (snapshot.data?.docs ?? [])
              .where((document) => document.data()['type'] == 'expense')
              .toList();

          final int totalCategories =
              _defaultCategories.length + documents.length;

          return Column(
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
                        'Custom categories are saved to your account '
                        'and can be renamed or deleted.',
                        style: TextStyle(color: Color(0xFF0F766E)),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$totalCategories Categories',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                    ),

                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddCategoryDialog(documents);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8B1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                  children: [
                    ..._defaultCategories.map((category) {
                      return _categoryTile(
                        name: category['name'].toString(),
                        icon: category['icon'] as IconData,
                        isDefault: true,
                      );
                    }),

                    ...documents.map((document) {
                      final data = document.data();

                      return _categoryTile(
                        name: data['name']?.toString() ?? 'Custom',
                        icon: Icons.category_outlined,
                        isDefault: false,
                        onEdit: () {
                          _renameCategory(
                            categoryId: document.id,
                            currentName: data['name']?.toString() ?? '',
                            documents: documents,
                          );
                        },
                        onDelete: () {
                          _deleteCategory(
                            categoryId: document.id,
                            categoryName:
                                data['name']?.toString() ?? 'Category',
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryTile({
    required String name,
    required IconData icon,
    required bool isDefault,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE6FFFC),
          child: Icon(icon, color: const Color(0xFF14B8B1)),
        ),

        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),

        subtitle: Text(
          isDefault
              ? 'Default category'
              : 'Custom category • Saved in Firestore',
        ),

        trailing: isDefault
            ? const Chip(label: Text('Default'))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Rename',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
      ),
    );
  }
}
