import 'package:flutter/material.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  static const _faqs = <({String question, String answer})>[
    (
      question: 'How is my financial data protected?',
      answer:
          'Your saved data is kept under your signed-in account and can only '
          'be accessed while that account is authenticated.',
    ),
    (
      question: 'How do I import a bank statement?',
      answer:
          'From the Dashboard, choose Import Bank Statement, select a CSV '
          'file, review every transaction, then tap Import Transactions.',
    ),
    (
      question: 'Why was my CSV file rejected?',
      answer:
          'The file must be readable CSV data with Date, Description, and '
          'Amount columns, or separate Debit and Credit columns.',
    ),
    (
      question: 'How do I reset my password?',
      answer:
          'Log out, choose Forgot password on the login screen, and enter '
          'your account email to request a reset link.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.help_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'How can we help?',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a common question below for a quick answer.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ..._faqs.map(
              (faq) => Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  title: Text(faq.question),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: double.infinity, child: Text(faq.answer)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
