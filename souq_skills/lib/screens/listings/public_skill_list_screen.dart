import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class PublicSkillListScreen extends StatelessWidget {
  const PublicSkillListScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Public Skill List',
    description: "View this member's public skills.",
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
