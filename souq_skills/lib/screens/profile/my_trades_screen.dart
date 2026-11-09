import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ProfileMyTradesScreen extends StatelessWidget {
  const ProfileMyTradesScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Profile My Trades',
    description: 'Your trade activity.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
