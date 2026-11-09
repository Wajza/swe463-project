import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Error',
    description: 'Something went wrong.',
    icon: Icons.error_outline,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
