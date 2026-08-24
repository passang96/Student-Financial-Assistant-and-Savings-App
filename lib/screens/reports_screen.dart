import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/calculation_service.dart';

class ReportsScreen extends StatelessWidget {
  ReportsScreen({super.key});

  final TransactionService transactionService = TransactionService();

  @override
  Widget build(BuildContext context) {
    // Current date
    final now = DateTime.now();

    // First day of current month
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Last day of current month
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), centerTitle: true),

      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: StreamBuilder<List<TransactionModel>>(
          stream: transactionService.getTransactionsByDateRange(
            startDate: startOfMonth,
            endDate: endOfMonth,
          ),

          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // Get transactions
            final transactions = snapshot.data ?? <TransactionModel>[];

            // Financial totals
            double totalIncome = 0.0;
            double totalExpenses = 0.0;

            // Store category totals
            final Map<String, double> categorySpending = {};

            // Calculate totals
            for (final transaction in transactions) {
              final double amount = transaction.amount;

              final String type = transaction.type.toLowerCase();

              final String category = transaction.category.trim().isEmpty
                  ? 'Other'
                  : transaction.category;

              // Income
              if (type == 'income') {
                totalIncome += amount;
              }

              // Expense
              if (type == 'expense') {
                totalExpenses += amount;

                categorySpending[category] =
                    (categorySpending[category] ?? 0.0) + amount;
              }
            }

            // Calculate balance
            final double balance = CalculationService.calculateBalance(
              totalIncome,
              totalExpenses,
            );

            // Calculate available savings
            final double savings = CalculationService.calculateSavings(
              totalIncome,
              totalExpenses,
            );

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // Current Month heading
                  const Text(
                    'Current Month',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // Income Card
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.arrow_downward),
                      title: const Text('Income'),
                      trailing: Text(
                        '\$${totalIncome.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Expenses Card
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.arrow_upward),
                      title: const Text('Expenses'),
                      trailing: Text(
                        '\$${totalExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Balance Card
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet),
                      title: const Text('Balance'),
                      trailing: Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Savings Card
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.savings),
                      title: const Text('Available Savings'),
                      trailing: Text(
                        '\$${savings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Category Spending heading
                  const Text(
                    'Category Spending',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  // No expenses
                  if (categorySpending.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No expenses for this month.'),
                      ),
                    ),

                  // Category cards
                  ...categorySpending.entries.map((entry) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.category),
                        title: Text(entry.key),
                        trailing: Text(
                          '\$${entry.value.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Transaction count
                  Center(
                    child: Text(
                      '${transactions.length} transactions this month',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
