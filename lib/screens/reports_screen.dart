import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';
import '../services/calculation_service.dart';

class ReportsScreen extends StatelessWidget {
  ReportsScreen({super.key});

  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestoreService.getCurrentMonthTransactions(),

          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // Start totals
            double totalIncome = 0.0;
            double totalExpenses = 0.0;

            // Category spending
            Map<String, double> categorySpending = {};

            // Read Firestore transactions
            if (snapshot.hasData) {
              for (final doc in snapshot.data!.docs) {
                final data = doc.data();

                final double amount =
                    (data['amount'] as num?)?.toDouble() ?? 0.0;

                final String type =
                    data['type']?.toString().toLowerCase() ?? '';

                final String category = data['category']?.toString() ?? 'Other';

                // Income
                if (type == 'income') {
                  totalIncome += amount;
                }

                // Expense
                if (type == 'expense') {
                  totalExpenses += amount;

                  // Add expense to category
                  categorySpending[category] =
                      (categorySpending[category] ?? 0.0) + amount;
                }
              }
            }

            // Balance
            final double balance = CalculationService.calculateBalance(
              totalIncome,
              totalExpenses,
            );

            // Savings
            final double savings = CalculationService.calculateSavings(
              totalIncome,
              totalExpenses,
            );

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      title: const Text('Savings'),
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

                  const Text(
                    'Category Spending',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  if (categorySpending.isEmpty)
                    const Text('No expenses for this month.'),

                  ...categorySpending.entries.map(
                    (entry) => Card(
                      child: ListTile(
                        title: Text(entry.key),
                        trailing: Text('\$${entry.value.toStringAsFixed(2)}'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
