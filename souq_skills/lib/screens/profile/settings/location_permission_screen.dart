import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Location Permission',
    description: 'Location access and manual city selection.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
