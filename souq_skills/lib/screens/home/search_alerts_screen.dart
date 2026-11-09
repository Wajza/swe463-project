import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class SearchAlertsScreen extends StatelessWidget {
  const SearchAlertsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Search Alerts',
    description: 'Manage alerts for matching skills.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
