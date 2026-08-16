import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await notificationService.markAllAsRead();

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not mark notifications as read: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: Color(0xFF10BFB7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load notifications.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const _EmptyNotifications();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final document = notifications[index];

              return _NotificationCard(
                notificationId: document.id,
                data: document.data(),
                notificationService: notificationService,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notificationId,
    required this.data,
    required this.notificationService,
  });

  final String notificationId;
  final Map<String, dynamic> data;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    final String title = data['title']?.toString() ?? 'Notification';

    final String message = data['message']?.toString() ?? '';

    final String type = data['type']?.toString() ?? '';

    final bool isRead = data['isRead'] as bool? ?? false;

    final Timestamp? timestamp = data['createdAt'] is Timestamp
        ? data['createdAt'] as Timestamp
        : null;

    final DateTime? createdAt = timestamp?.toDate();

    final _NotificationAppearance appearance = _appearanceForType(type);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        if (isRead) {
          return;
        }

        try {
          await notificationService.markAsRead(notificationId);
        } catch (e) {
          if (!context.mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not update notification: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0FDFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? const Color(0xFFE5E7EB) : const Color(0xFF99F6E4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: appearance.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(appearance.icon, color: appearance.iconColor),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),

                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 5, left: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10BFB7),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _timeLabel(createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),

                      const Spacer(),

                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: (value) async {
                          try {
                            if (value == 'read') {
                              await notificationService.markAsRead(
                                notificationId,
                              );
                            }

                            if (value == 'unread') {
                              await notificationService.markAsUnread(
                                notificationId,
                              );
                            }

                            if (value == 'delete') {
                              await notificationService.deleteNotification(
                                notificationId,
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not update notification: $e',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          if (!isRead)
                            const PopupMenuItem(
                              value: 'read',
                              child: Text('Mark as read'),
                            ),
                          if (isRead)
                            const PopupMenuItem(
                              value: 'unread',
                              child: Text('Mark as unread'),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 72,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Budget warnings and savings-goal updates will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationAppearance {
  const _NotificationAppearance({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
}

_NotificationAppearance _appearanceForType(String type) {
  switch (type) {
    case 'budget_warning':
      return const _NotificationAppearance(
        icon: Icons.warning_amber_rounded,
        iconColor: Color(0xFFD97706),
        backgroundColor: Color(0xFFFFF7ED),
      );

    case 'budget_exceeded':
      return const _NotificationAppearance(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        backgroundColor: Color(0xFFFFEEEE),
      );

    case 'goal_progress':
      return const _NotificationAppearance(
        icon: Icons.trending_up,
        iconColor: Color(0xFF2563EB),
        backgroundColor: Color(0xFFEFF6FF),
      );

    case 'goal_achieved':
      return const _NotificationAppearance(
        icon: Icons.emoji_events_outlined,
        iconColor: Color(0xFF7C3AED),
        backgroundColor: Color(0xFFF5F3FF),
      );

    default:
      return const _NotificationAppearance(
        icon: Icons.notifications_outlined,
        iconColor: Color(0xFF0E9F99),
        backgroundColor: Color(0xFFE8FAF5),
      );
  }
}

String _timeLabel(DateTime? date) {
  if (date == null) {
    return 'Just now';
  }

  final now = DateTime.now();

  final difference = now.difference(date);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }

  if (difference.inDays == 1) {
    return 'Yesterday';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  }

  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
