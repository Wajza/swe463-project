import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class GroupTradeCompletionScreen extends StatelessWidget {
  const GroupTradeCompletionScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Group Trade Completion',
    description: 'Confirm group exchange completion.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
