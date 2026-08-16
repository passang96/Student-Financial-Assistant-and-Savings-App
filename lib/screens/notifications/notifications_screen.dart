import 'package:flutter/material.dart';

import '../../models/financial_notification.dart';

enum _NotificationFilter { all, unread }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.initialNotifications = FinancialNotification.demoNotifications,
    this.onNotificationsChanged,
  });

  final List<FinancialNotification> initialNotifications;
  final ValueChanged<List<FinancialNotification>>? onNotificationsChanged;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<FinancialNotification> _notifications;
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _notifications = List.of(widget.initialNotifications);
  }

  int get _unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  List<FinancialNotification> get _visibleNotifications {
    if (_filter == _NotificationFilter.unread) {
      return _notifications
          .where((notification) => !notification.isRead)
          .toList();
    }
    return _notifications;
  }

  void _notifyParent() {
    widget.onNotificationsChanged?.call(List.unmodifiable(_notifications));
  }

  void _markAsRead(FinancialNotification notification) {
    if (notification.isRead) {
      return;
    }

    setState(() {
      final index = _notifications.indexWhere(
        (item) => item.id == notification.id,
      );
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });
    _notifyParent();
  }

  void _markAllAsRead() {
    if (_unreadCount == 0) {
      return;
    }

    setState(() {
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final visibleNotifications = _visibleNotifications;
    final today = visibleNotifications
        .where((notification) => notification.isToday)
        .toList();
    final earlier = visibleNotifications
        .where((notification) => !notification.isToday)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _unreadCount == 0 ? null : _markAllAsRead,
            icon: const Icon(Icons.done_all_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: _NotificationSummary(unreadCount: _unreadCount),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('All (${_notifications.length})'),
                          selected: _filter == _NotificationFilter.all,
                          onSelected: (_) =>
                              setState(() => _filter = _NotificationFilter.all),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Unread ($_unreadCount)'),
                          selected: _filter == _NotificationFilter.unread,
                          onSelected: (_) => setState(
                            () => _filter = _NotificationFilter.unread,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (visibleNotifications.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyNotifications(
                      showAll: () =>
                          setState(() => _filter = _NotificationFilter.all),
                    ),
                  )
                else ...[
                  if (today.isNotEmpty)
                    _NotificationSection(
                      title: 'Today',
                      notifications: today,
                      onTap: _markAsRead,
                    ),
                  if (earlier.isNotEmpty)
                    _NotificationSection(
                      title: 'Earlier',
                      notifications: earlier,
                      onTap: _markAsRead,
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countMessage = unreadCount == 0
        ? 'You are all caught up.'
        : '$unreadCount ${unreadCount == 1 ? 'update' : 'updates'} need your attention.';

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00695C).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your money updates',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    countMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
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

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({
    required this.title,
    required this.notifications,
    required this.onTap,
  });

  final String title;
  final List<FinancialNotification> notifications;
  final ValueChanged<FinancialNotification> onTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            );
          }

          final notification = notifications[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NotificationCard(
              notification: notification,
              onTap: () => onTap(notification),
            ),
          );
        }, childCount: notifications.length + 1),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final FinancialNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _NotificationStyle.forType(notification.type);

    return Semantics(
      button: !notification.isRead,
      label: notification.isRead
          ? notification.title
          : '${notification.title}, unread. Tap to mark as read.',
      child: Material(
        color: notification.isRead
            ? theme.colorScheme.surface
            : style.tintColor.withValues(alpha: 0.38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: notification.isRead
                ? theme.colorScheme.outlineVariant.withValues(alpha: 0.55)
                : style.color.withValues(alpha: 0.22),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: style.tintColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.icon, color: style.color, size: 25),
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
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: style.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                      if (notification.progress case final progress?) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 7,
                            backgroundColor: style.color.withValues(
                              alpha: 0.12,
                            ),
                            valueColor: AlwaysStoppedAnimation(style.color),
                          ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          if (notification.amountLabel case final amount?) ...[
                            Flexible(
                              child: Text(
                                amount,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: style.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•',
                              style: TextStyle(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            notification.timeLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.showAll});

  final VoidCallback showAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 38,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No unread notifications',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You are up to date with your budgets and savings goals.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: showAll, child: const Text('View all updates')),
        ],
      ),
    );
  }
}

class _NotificationStyle {
  const _NotificationStyle({
    required this.color,
    required this.tintColor,
    required this.icon,
  });

  final Color color;
  final Color tintColor;
  final IconData icon;

  static _NotificationStyle forType(FinancialNotificationType type) {
    return switch (type) {
      FinancialNotificationType.budgetWarning => const _NotificationStyle(
        color: Color(0xFFB45309),
        tintColor: Color(0xFFFFF1D6),
        icon: Icons.account_balance_wallet_outlined,
      ),
      FinancialNotificationType.budgetExceeded => const _NotificationStyle(
        color: Color(0xFFB42318),
        tintColor: Color(0xFFFEE4E2),
        icon: Icons.warning_amber_rounded,
      ),
      FinancialNotificationType.goalProgress => const _NotificationStyle(
        color: Color(0xFF175CD3),
        tintColor: Color(0xFFE7F0FF),
        icon: Icons.trending_up_rounded,
      ),
      FinancialNotificationType.goalAchieved => const _NotificationStyle(
        color: Color(0xFF027A48),
        tintColor: Color(0xFFDDF7EA),
        icon: Icons.emoji_events_outlined,
      ),
    };
  }
}
