import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class BadgeDetailsScreen extends StatelessWidget {
  const BadgeDetailsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Badge Details',
    description: 'Badge progress and requirements.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
