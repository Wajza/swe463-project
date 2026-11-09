import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Community Guidelines',
    description: 'Community rules.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
