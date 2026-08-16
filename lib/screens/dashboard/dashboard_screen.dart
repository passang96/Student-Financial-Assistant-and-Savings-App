import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/financial_notification.dart';
import '../../widgets/user_details_card.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoggingOut = false;
  List<FinancialNotification> _notifications = List.of(
    FinancialNotification.demoNotifications,
  );

  int get _unreadNotificationCount =>
      _notifications.where((notification) => !notification.isRead).length;

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          initialNotifications: _notifications,
          onNotificationsChanged: (notifications) {
            if (mounted) {
              setState(() => _notifications = List.of(notifications));
            }
          },
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoggingOut = true);
    final result = await widget.authController.logout();

    if (result.isSuccess) {
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
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: _openNotifications,
                icon: Badge(
                  isLabelVisible: _unreadNotificationCount > 0,
                  label: Text('$_unreadNotificationCount'),
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
              IconButton(
                tooltip: 'Profile',
                onPressed: user == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            authController: widget.authController,
                          ),
                        ),
                      ),
                icon: const Icon(Icons.account_circle_outlined),
              ),
              IconButton(
                tooltip: 'Log out',
                onPressed: _isLoggingOut ? null : _logout,
                icon: _isLoggingOut
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: user == null
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Hello, ${UserDetailsCard.displayNameFor(user)}!',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your financial overview will appear here.',
                            ),
                            const SizedBox(height: 24),
                            UserDetailsCard(user: user),
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
