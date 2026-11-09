import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Settings',
    description: 'Account, privacy, and app preferences.',
    icon: Icons.settings_outlined,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
