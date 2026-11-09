import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class DirectChatScreen extends StatelessWidget {
  const DirectChatScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Direct Chat',
    description: 'Chat with a member.',
    icon: Icons.chat_bubble_outline,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
