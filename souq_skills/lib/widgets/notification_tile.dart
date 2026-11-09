import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/models/notification.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.onTap,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: Icon(
        notification.isRead
            ? Icons.notifications_none
            : Icons.notifications_active,
        color: context.colors.primary,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? null : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${notification.message}\n'
        '${AppFormatters.dateTime(notification.createdAt)}',
      ),
      isThreeLine: true,
    ),
  );
}
