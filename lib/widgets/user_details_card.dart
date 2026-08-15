import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserDetailsCard extends StatelessWidget {
  const UserDetailsCard({super.key, required this.user, this.showUid = false});

  final User user;
  final bool showUid;

  static String displayNameFor(User user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Student';
  }

  @override
  Widget build(BuildContext context) {
    final name = displayNameFor(user);

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
                    name.substring(0, 1).toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (user.email != null) ...[
                        const SizedBox(height: 3),
                        Text(user.email!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (showUid) ...[
              const Divider(height: 32),
              Text(
                'Firebase UID',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              SelectableText(user.uid),
            ],
          ],
        ),
      ),
    );
  }
}
