import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class AccountDetailsScreen extends StatelessWidget {
  const AccountDetailsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Account Details',
    description: 'Name, username, city, and verified phone.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
