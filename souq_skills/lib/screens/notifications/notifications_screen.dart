import 'package:flutter/material.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/services/notification_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _open(BuildContext context, AppNotification notification) {
    NotificationService().markRead(notification.id);
    final route = notification.route;
    if (route != null) context.open(route, args: notification.routeArgument);
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) => AppPage(
      title: 'Notifications',
      actions: [
        IconButton(
          tooltip: 'Mark all as read',
          onPressed: NotificationService().markAllRead,
          icon: const Icon(Icons.done_all),
        ),
      ],
      emptyState: const EmptyState(
        title: 'You are all caught up',
        message: 'Trade and message updates will appear here.',
        icon: Icons.notifications_none,
      ),
      children: [
        for (final item in NotificationService().all())
          NotificationTile(
            notification: item,
            onTap: () => _open(context, item),
          ),
      ],
    ),
  );
}
