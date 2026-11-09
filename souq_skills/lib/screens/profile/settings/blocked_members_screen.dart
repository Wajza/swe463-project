import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class BlockedMembersScreen extends StatelessWidget {
  const BlockedMembersScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Blocked Members',
    description: 'Members you have blocked.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
