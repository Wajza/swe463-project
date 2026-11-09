import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Loading',
    description: 'Loading data.',
    icon: Icons.hourglass_empty,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
