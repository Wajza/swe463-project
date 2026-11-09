import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class SkillCategoryScreen extends StatelessWidget {
  const SkillCategoryScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Skill Category',
    description: 'Choose the category for your skill.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
