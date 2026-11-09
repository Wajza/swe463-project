import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Notifications',
    description: 'Your notifications.',
    icon: Icons.notifications_none,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
