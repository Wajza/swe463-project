import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Notification Preferences',
    description: 'Trade, message, group, and search alerts.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
