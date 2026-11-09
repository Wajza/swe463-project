import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/notification_service.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  void _finish(BuildContext context, {required bool enabled}) {
    NotificationService().setAllEnabled(enabled);
    context.resetTo(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) => StatusPage(
    pageTitle: 'Stay updated',
    showBackButton: false,
    icon: Icons.notifications_active_outlined,
    title: 'Turn on notifications',
    message: 'Hear about new proposals, messages, and ratings as they happen.',
    actions: [
      SouqButton(
        label: 'Allow notifications',
        onPressed: () => _finish(context, enabled: true),
      ),
      SouqButton(
        label: 'Not now',
        outlined: true,
        onPressed: () => _finish(context, enabled: false),
      ),
    ],
  );
}
