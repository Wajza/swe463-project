import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class CounterofferScreen extends StatelessWidget {
  const CounterofferScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Counteroffer',
    description: 'Send or review a counteroffer.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
