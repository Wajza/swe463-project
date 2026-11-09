import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Badges',
    description: 'Earned and locked badges.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
