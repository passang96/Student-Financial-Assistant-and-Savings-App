import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();

  final _notesController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  final List<String> _categories = [
    'Rent',
    'Food',
    'Transport',
    'Bills',
    'Shopping',
    'Education/Study',
    'Entertainment',
    'Other',
  ];

  String? _selectedCategory;

  DateTime _selectedDate = DateTime.now();

  bool _isSaving = false;

  String get _formattedDate {
    return '${_selectedDate.day.toString().padLeft(2, '0')}/'
        '${_selectedDate.month.toString().padLeft(2, '0')}/'
        '${_selectedDate.year}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _chooseDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final double amount = double.parse(_amountController.text.trim());

    final String category = _selectedCategory!;

    final String notes = _notesController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestoreService.addTransaction(
        type: 'expense',
        amount: amount,
        category: category,
        date: _selectedDate,
        notes: notes,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _amountController.clear();
      _notesController.clear();

      setState(() {
        _selectedCategory = null;
        _selectedDate = DateTime.now();
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save expense: $e'),
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
        title: const Text('Add Expense'),
        backgroundColor: const Color(0xFF14B8B1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),

            child: Card(
              elevation: 2,
              color: Colors.white,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),

              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Form(
                  key: _formKey,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Expense details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Enter the details of your expense.',
                        style: TextStyle(color: Color(0xFF667085)),
                      ),

                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _amountController,

                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),

                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                          prefixText: '\$ ',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }

                          final amount = double.tryParse(value.trim());

                          if (amount == null || amount <= 0) {
                            return 'Enter an amount greater than zero';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,

                        decoration: InputDecoration(
                          labelText: 'Category',

                          prefixIcon: const Icon(Icons.category_outlined),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),

                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      InkWell(
                        onTap: _isSaving ? null : _chooseDate,

                        borderRadius: BorderRadius.circular(12),

                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',

                            prefixIcon: const Icon(Icons.calendar_today),

                            suffixIcon: const Icon(Icons.arrow_drop_down),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),

                          child: Text(_formattedDate),
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _notesController,

                        enabled: !_isSaving,

                        maxLines: 4,
                        maxLength: 200,

                        decoration: InputDecoration(
                          labelText: 'Notes or description',

                          hintText: 'Enter optional information',

                          alignLabelWithHint: true,

                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 70),
                            child: Icon(Icons.notes),
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 52,

                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveExpense,

                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),

                          label: Text(
                            _isSaving ? 'Saving...' : 'Save Expense',

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8B1),
                            foregroundColor: Colors.white,

                            disabledBackgroundColor: const Color(0xFF8DDDD9),

                            disabledForegroundColor: Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
