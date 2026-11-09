import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class DisputeCaseDetailsScreen extends StatelessWidget {
  const DisputeCaseDetailsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Dispute Case Details',
    description: 'Track your dispute.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
