import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ShareListingScreen extends StatelessWidget {
  const ShareListingScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Share Listing',
    description: 'Share a skill listing.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
