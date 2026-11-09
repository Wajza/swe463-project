import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class AppPreferencesScreen extends StatelessWidget {
  const AppPreferencesScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'App Preferences',
    description: 'Appearance and general preferences.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
