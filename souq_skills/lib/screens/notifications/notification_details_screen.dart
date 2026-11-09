import 'package:flutter/material.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/notification.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/notification_service.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class NotificationDetailsScreen extends StatelessWidget {
  const NotificationDetailsScreen({required this.notificationId, super.key});

  final String notificationId;

  @override
  Widget build(BuildContext context) => LiveEntity<AppNotification>(
    find: () => NotificationService().byId(notificationId),
    builder: (context, notification) {
      final route = notification.route;
      return StatusPage(
        pageTitle: 'Notification',
        icon: Icons.notifications_none,
        title: notification.title,
        message:
            '${notification.message}\n\n'
            '${AppFormatters.dateTime(notification.createdAt)}',
        actions: [
          if (route != null)
            SouqButton(
              label: 'Open',
              onPressed: () =>
                  context.open(route, args: notification.routeArgument),
            ),
        ],
      );
    },
  );
}
