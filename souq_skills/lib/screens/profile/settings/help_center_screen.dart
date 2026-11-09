import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Help Center',
    description: 'Answers about exchanges and safety.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
