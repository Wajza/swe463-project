import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Not Found',
    description: 'This page was not found.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
