import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Privacy Settings',
    description: 'Profile and location visibility.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
