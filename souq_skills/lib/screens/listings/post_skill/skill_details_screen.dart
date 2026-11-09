import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class SkillDetailsScreen extends StatelessWidget {
  const SkillDetailsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Skill Details',
    description: 'Describe the skill you offer.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
