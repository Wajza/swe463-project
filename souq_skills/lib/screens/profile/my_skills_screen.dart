import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class MySkillsScreen extends StatelessWidget {
  const MySkillsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'My Skills',
    description: 'Skills you offer and want.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
