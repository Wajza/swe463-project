import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class GroupTradeDetailsScreen extends StatelessWidget {
  const GroupTradeDetailsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Group Trade Details',
    description: 'Group owner, members, skills, and status.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
