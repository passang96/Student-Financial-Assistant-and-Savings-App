import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: const Text(
          'Privacy Policy',
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
                    Icons.privacy_tip_outlined,
                    color: AppColors.primaryTeal,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your privacy matters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'This page explains how the Student Financial Assistant uses and stores information within the app.',
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

            const _PolicySection(
              title: '1. Information We Store',
              text:
                  'The app may store information you provide, including your name, email address, phone number, university, transactions, budgets, categories, savings goals and in-app notifications.',
            ),

            const _PolicySection(
              title: '2. Financial Transaction Data',
              text:
                  'Transaction information entered manually or imported from a CSV file is used to calculate income, expenses, budgets, reports, savings information and other financial insights inside the app.',
            ),

            const _PolicySection(
              title: '3. Bank CSV Imports',
              text:
                  'The app does not directly connect to your bank account. CSV transaction files are selected by the user and processed for transaction import. Users should review imported transactions before saving them.',
            ),

            const _PolicySection(
              title: '4. Firebase Authentication',
              text:
                  'Firebase Authentication is used to manage user login and account access. Each signed-in user is identified using their Firebase user ID so that financial records can be stored separately for each account.',
            ),

            const _PolicySection(
              title: '5. Firebase Firestore',
              text:
                  'The app uses Firebase Firestore to store user-related information such as transactions, budgets, savings goals, categories, notifications and profile details.',
            ),

            const _PolicySection(
              title: '6. How Information Is Used',
              text:
                  'Stored information is used only to provide app functionality such as financial calculations, transaction history, spending reports, budget monitoring, savings goal tracking and notifications.',
            ),

            const _PolicySection(
              title: '7. Notifications',
              text:
                  'The app may generate in-app notifications for events such as approaching a budget limit, exceeding a budget, reaching savings goal milestones or achieving a savings goal.',
            ),

            const _PolicySection(
              title: '8. Data Separation',
              text:
                  'Financial information is stored under the currently authenticated Firebase user ID. This helps keep each user’s records separate from other users.',
            ),

            const _PolicySection(
              title: '9. Data Accuracy',
              text:
                  'Users are responsible for reviewing manually entered and imported financial information. Automatic transaction categorisation is a suggestion and may not always identify a transaction correctly.',
            ),

            const _PolicySection(
              title: '10. Bank Credentials',
              text:
                  'The current version of the app does not request, collect or store online banking usernames, passwords or bank login credentials.',
            ),

            const _PolicySection(
              title: '11. Data Retention',
              text:
                  'Transactions and other saved records remain available in the user account unless they are edited or deleted. Starting a new monthly budget period does not automatically delete historical transactions.',
            ),

            const _PolicySection(
              title: '12. Security',
              text:
                  'The app uses Firebase services for authentication and cloud data storage. Users should protect their account credentials and avoid sharing their login information with others.',
            ),

            const _PolicySection(
              title: '13. Educational Project',
              text:
                  'This application is currently developed as a student project and financial information shown by the app should be treated as informational guidance rather than professional financial advice.',
            ),

            const _PolicySection(
              title: '14. Changes to This Policy',
              text:
                  'This privacy information may be updated as new features or integrations are added to the application.',
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCCFBF1)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.primaryTeal),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The Student Financial Assistant is not a bank and does not currently provide direct bank-account connectivity or professional financial advice.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
