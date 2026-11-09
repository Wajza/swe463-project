import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class SafetyCentreScreen extends StatelessWidget {
  const SafetyCentreScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Safety Centre',
    description: 'Safety guidance.',
    icon: Icons.shield_outlined,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
