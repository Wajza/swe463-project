import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ReportReceivedScreen extends StatelessWidget {
  const ReportReceivedScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Report Received',
    description: 'Your report was received.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
