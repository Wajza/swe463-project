import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class NotificationDetailsScreen extends StatelessWidget {
  const NotificationDetailsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Notification Details',
    description: 'Notification details.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
