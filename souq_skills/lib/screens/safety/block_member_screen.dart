import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class BlockMemberScreen extends StatelessWidget {
  const BlockMemberScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Block Member',
    description: 'Block a member.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
