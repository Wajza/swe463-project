import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ScheduleSessionScreen extends StatelessWidget {
  const ScheduleSessionScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Schedule Session',
    description: 'Schedule a skill exchange session.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
