import 'package:flutter/material.dart';
import 'screens/reports/reports_screen.dart';

void main() {
  runApp(const ReportsPreviewApp());
}

class ReportsPreviewApp extends StatelessWidget {
  const ReportsPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReportsScreen(),
    );
  }
}