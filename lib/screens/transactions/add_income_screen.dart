import 'package:flutter/material.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _incomeSources = [
    'Salary',
    'Business',
    'Allowance',
    'Scholarship',
    'Gift',
    'Other',
  ];

  String? _selectedSource;
  DateTime _selectedDate = DateTime.now();

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

  void _saveIncome() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final income = {
      'amount': double.parse(_amountController.text.trim()),
      'category': _selectedSource,
      'date': _selectedDate,
      'notes': _notesController.text.trim(),
      'type': 'income',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Income saved successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Passang will connect this income information to Firestore.
    debugPrint('Income: $income');

    _amountController.clear();
    _notesController.clear();

    setState(() {
      _selectedSource = null;
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Add Income'),
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
                        'Income details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter the details of your income.',
                        style: TextStyle(
                          color: Color(0xFF667085),
                        ),
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
                        initialValue: _selectedSource,
                        decoration: InputDecoration(
                          labelText: 'Income source',
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _incomeSources.map((source) {
                          return DropdownMenuItem<String>(
                            value: source,
                            child: Text(source),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSource = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an income source';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      InkWell(
                        onTap: _chooseDate,
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
                        maxLines: 4,
                        maxLength: 200,
                        decoration: InputDecoration(
                          labelText: 'Notes',
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
                          onPressed: _saveIncome,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text(
                            'Save Income',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8B1),
                            foregroundColor: Colors.white,
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