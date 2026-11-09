import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Offline',
    description: 'You are offline.',
    icon: Icons.cloud_off_outlined,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
