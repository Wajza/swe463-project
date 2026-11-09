import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class EditListingScreen extends StatelessWidget {
  const EditListingScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Edit Listing',
    description: 'Edit, pause, or remove a listing.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
