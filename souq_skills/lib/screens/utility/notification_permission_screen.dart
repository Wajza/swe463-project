import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Notification Permission',
    description: 'Why notifications are useful.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
