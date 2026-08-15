import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/logout_button.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.name = 'Alex Johnson',
    this.email = 'alex.johnson@student.edu',
    this.university = 'State University',
  });

  final String name;
  final String email;
  final String university;

  void _handleLogout(BuildContext context) {
    // TODO: hook up to real auth sign-out (e.g. FirebaseAuth.instance.signOut())
    // and navigate back to the Login screen, clearing the nav stack.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.primaryTeal.withValues(
                        alpha: 0.15,
                      ),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      university,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          initialName: name,
                          initialEmail: email,
                          initialUniversity: university,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    side: const BorderSide(color: AppColors.primaryTeal),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Account'),
              _ProfileMenuTile(
                icon: Icons.savings_outlined,
                label: 'Savings Goals',
                onTap: () {},
              ),
              _ProfileMenuTile(
                icon: Icons.receipt_long_outlined,
                label: 'Expense History',
                onTap: () {},
              ),
              _ProfileMenuTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Support'),
              _ProfileMenuTile(
                icon: Icons.help_outline,
                label: 'Help & FAQ',
                onTap: () {},
              ),
              _ProfileMenuTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () {},
              ),
              const SizedBox(height: 28),
              LogoutButton(onConfirmLogout: () => _handleLogout(context)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Icon(icon, color: AppColors.primaryTeal),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
