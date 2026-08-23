import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      const _FaqItem(
        question: 'How do I add an income or expense?',
        answer:
            'Open the Expense tab or Transaction History, then choose Add Income or Add Expense. Enter the amount, category, date and notes, then save the transaction.',
      ),
      const _FaqItem(
        question: 'Can I import transactions from my bank?',
        answer:
            'Yes. Open Transaction History and select Import Bank Transactions. Choose a CSV transaction file exported from your online banking. The app will read the transactions, suggest income or expense types and categories, and show a preview before anything is saved.',
      ),
      const _FaqItem(
        question: 'Do I need to convert a PDF bank statement into CSV?',
        answer:
            'No. The CSV import feature is designed for transaction files exported directly from online banking. You should not need to convert a PDF statement manually.',
      ),
      const _FaqItem(
        question: 'Why does the app ask me to review imported transactions?',
        answer:
            'Automatic categorisation is a suggestion. Bank descriptions can be unclear, so the preview screen allows you to check and correct the transaction type or category before importing.',
      ),
      const _FaqItem(
        question: 'What is Net Balance?',
        answer:
            'Net Balance is the amount remaining after your selected income and expenses are calculated. It is calculated automatically from your saved transactions.',
      ),
      const _FaqItem(
        question: 'What are Available Funds?',
        answer:
            'Available Funds represent your Net Balance after money already allocated to savings goals is considered. This helps separate spending money from money you have intentionally saved.',
      ),
      const _FaqItem(
        question: 'What does Safe to Spend Today mean?',
        answer:
            'Safe to Spend Today is a financial guidance value calculated from your available funds, budget information and recent spending behaviour. It is intended to help you avoid overspending.',
      ),
      const _FaqItem(
        question: 'How do budgets work?',
        answer:
            'You can set an overall monthly budget and individual category budgets. The app compares your real expense transactions with those limits and automatically updates the amount spent and remaining.',
      ),
      const _FaqItem(
        question: 'When will I receive budget notifications?',
        answer:
            'The app can notify you when you approach a budget limit and when a budget is reached or exceeded. Duplicate alerts for the same milestone are prevented.',
      ),
      const _FaqItem(
        question: 'How do Savings Goals work?',
        answer:
            'Create a goal with a target amount and target date, then record contributions. The app automatically calculates your progress, remaining amount and whether the goal has been achieved.',
      ),
      const _FaqItem(
        question: 'When do savings goal notifications appear?',
        answer:
            'Savings goal notifications can appear when you reach important progress milestones such as 25%, 50%, 75% and 100%.',
      ),
      const _FaqItem(
        question: 'Can I view transactions for different periods?',
        answer:
            'Yes. Transaction History supports weekly, fortnightly, monthly and custom date ranges. You can also filter by income or expense type and by category.',
      ),
      const _FaqItem(
        question: 'What information is shown in Reports?',
        answer:
            'Reports use your saved transaction data to show income, expenses, net cash flow, savings goal totals, category spending and comparisons with the previous period.',
      ),
      const _FaqItem(
        question: 'Will my old transactions disappear next month?',
        answer:
            'No. Transactions are stored in Firestore and remain available. A new monthly budget period does not delete your previous transaction history.',
      ),
      const _FaqItem(
        question: 'Can I edit or delete a transaction?',
        answer:
            'Yes. Open Transaction History and use the menu beside a transaction to edit or delete it. Financial calculations update automatically after changes.',
      ),
      const _FaqItem(
        question: 'Can I change my profile information?',
        answer:
            'Yes. Open Profile and select Edit Profile to update your name, phone number and university. Your login email is managed separately through Firebase Authentication.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: const Text(
          'Help & FAQ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.help_outline,
                    color: AppColors.primaryTeal,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Find answers about transactions, bank imports, budgets, savings goals, reports and your profile.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            ...faqs.map(
              (faq) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ExpansionTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  iconColor: AppColors.primaryTeal,
                  collapsedIconColor: AppColors.textSecondary,
                  title: Text(
                    faq.question,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        faq.answer,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
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

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}
