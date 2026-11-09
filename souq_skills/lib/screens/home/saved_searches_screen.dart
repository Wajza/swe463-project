import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class SavedSearchesScreen extends StatelessWidget {
  const SavedSearchesScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Saved Searches',
    description: 'Your saved searches.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
