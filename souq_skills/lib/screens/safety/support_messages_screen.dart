import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class SupportMessagesScreen extends StatelessWidget {
  const SupportMessagesScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Support Messages',
    description: 'Messages with support.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
