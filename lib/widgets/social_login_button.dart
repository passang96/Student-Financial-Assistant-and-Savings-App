import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Square icon button used for social sign-in options (Google, Apple, Email)
/// on the Login and Register screens.
///
/// Usage (matches login_screen.dart / register_screen.dart):
/// ```dart
/// SocialLoginButton(
///   icon: Icons.g_mobiledata,
///   onPressed: _handleGoogleLogin,
/// )
/// ```
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 52,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
