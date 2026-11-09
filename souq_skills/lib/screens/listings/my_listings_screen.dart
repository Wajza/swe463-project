import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'My Listings',
    description: 'Manage your published listings.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
