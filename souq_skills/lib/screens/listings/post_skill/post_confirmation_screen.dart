import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class PostConfirmationScreen extends StatelessWidget {
  const PostConfirmationScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Post Confirmation',
    description: 'Your listing has been published.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
