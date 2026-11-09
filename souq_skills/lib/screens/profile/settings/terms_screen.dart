import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Terms',
    description: 'Terms and conditions.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
