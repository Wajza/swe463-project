import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class GroupTradeChatScreen extends StatelessWidget {
  const GroupTradeChatScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Group Trade Chat',
    description: 'Chat with the group.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
