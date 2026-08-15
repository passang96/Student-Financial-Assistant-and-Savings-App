import 'package:flutter/material.dart';
import 'screens/transactions/transaction_history_screen.dart';

void main() {
  runApp(const TransactionsPreviewApp());
}

class TransactionsPreviewApp extends StatelessWidget {
  const TransactionsPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TransactionHistoryScreen(),
    );
  }
}