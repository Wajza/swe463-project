import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ProposalInsideChat extends StatelessWidget {
  const ProposalInsideChat({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Proposal Inside Chat',
    description: 'Create a proposal inside the chat.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
