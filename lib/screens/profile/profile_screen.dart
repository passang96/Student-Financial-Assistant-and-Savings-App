import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user_profile.dart';
import '../help/help_faq_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final StreamSubscription<User?> _authStateSubscription;
  late Future<UserProfile?> _profileFuture;
  bool _isLoggingOut = false;
  bool _isReturningToLogin = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.authController.loadProfile();
    _authStateSubscription = widget.authController.authStateChanges.listen(
      _handleAuthStateChange,
    );
  }

  void _handleAuthStateChange(User? user) {
    if (user != null || _isLoggingOut || _isReturningToLogin || !mounted) {
      return;
    }

    _isReturningToLogin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _editProfile(UserProfile profile) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          authController: widget.authController,
          profile: profile,
        ),
      ),
    );

    if (!mounted || message == null) {
      return;
    }
    setState(() {
      _profileFuture = widget.authController.loadProfile();
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openHelp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HelpFaqScreen()));
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isLoggingOut = true);
    final result = await widget.authController.logout();

    if (result.isSuccess) {
      if (navigator.mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
      if (messenger.mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(result.message)));
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() => _isLoggingOut = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: FutureBuilder<UserProfile?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final profile = snapshot.data;
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (profile == null) {
              return const Center(
                child: Text('Your session has expired. Please log in again.'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileDetailsCard(profile: profile),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        key: const Key('edit-profile-button'),
                        onPressed: _isLoggingOut
                            ? null
                            : () => _editProfile(profile),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isLoggingOut ? null : _openHelp,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Help & FAQ'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('profile-logout-button'),
                        onPressed: _isLoggingOut ? null : _logout,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: _isLoggingOut
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout),
                        label: const Text('Log out'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.displayName.isEmpty
        ? (profile.email.isEmpty ? 'Student' : profile.email.split('@').first)
        : profile.displayName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        key: const Key('profile-display-name'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (profile.email.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(profile.email),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text('Firebase UID', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            SelectableText(profile.uid),
          ],
        ),
      ),
    );
  }
}
