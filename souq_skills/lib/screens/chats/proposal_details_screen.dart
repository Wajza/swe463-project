import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ProposalDetailsScreen extends StatelessWidget {
  const ProposalDetailsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Proposal Details',
    description: 'View the complete proposal.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
