import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../widgets/user_details_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final StreamSubscription<User?> _authStateSubscription;
  bool _isLoggingOut = false;
  bool _isReturningToLogin = false;

  @override
  void initState() {
    super.initState();
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
    return StreamBuilder<User?>(
      stream: widget.authController.userChanges,
      initialData: widget.authController.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: user == null
                      ? const CircularProgressIndicator()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            UserDetailsCard(user: user, showUid: true),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
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
            ),
          ),
        );
      },
    );
  }
}
