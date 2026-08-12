import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() {
  runApp(const DashboardPreviewApp());
}

class DashboardPreviewApp extends StatelessWidget {
  const DashboardPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}