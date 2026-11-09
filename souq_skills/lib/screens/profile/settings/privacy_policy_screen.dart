import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Privacy Policy',
    description: 'Privacy policy.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
