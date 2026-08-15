import 'package:flutter/material.dart';
import 'screens/budget/budget_screen.dart';

void main() {
  runApp(const BudgetPreviewApp());
}

class BudgetPreviewApp extends StatelessWidget {
  const BudgetPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BudgetScreen(),
    );
  }
}