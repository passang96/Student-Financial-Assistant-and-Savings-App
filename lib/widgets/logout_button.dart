import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable logout control. Shows a confirmation dialog before calling
/// [onConfirmLogout], so a stray tap can't sign the user out by accident.
///
/// Usage:
/// ```dart
/// LogoutButton(
///   onConfirmLogout: () {
///     // clear session / call FirebaseAuth.instance.signOut() / navigate
///   },
/// )
/// ```
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key, required this.onConfirmLogout});

  final VoidCallback onConfirmLogout;

  Future<void> _showConfirmDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Log out?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Log out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onConfirmLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showConfirmDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Log Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
