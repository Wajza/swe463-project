import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Delete Account',
    description: 'Review account deletion before confirming.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
