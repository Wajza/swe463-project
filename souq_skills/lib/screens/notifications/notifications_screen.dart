import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
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
    context.open(AppRoutes.notificationDetails, args: notification.id);
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final notifications = NotificationService().all();
      return AppPage(
        emptyState: const EmptyState(
          title: 'You are all caught up',
          message: 'Trade and message updates will appear here.',
          icon: Icons.notifications_none,
        ),
        title: 'Notifications',
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: NotificationService().markAllRead,
            icon: const Icon(Icons.done_all),
          ),
        ],
        children: [
          for (final item in notifications)
            NotificationTile(
              notification: item,
              onTap: () => _open(context, item),
            ),
        ],
      );
    },
  );
}
