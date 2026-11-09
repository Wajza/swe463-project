import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'About',
    description: 'About Souq Skills.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
