import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class PublicMemberProfileScreen extends StatelessWidget {
  const PublicMemberProfileScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Public Member Profile',
    description: "A member's public profile.",
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
