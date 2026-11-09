import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ReportMemberScreen extends StatelessWidget {
  const ReportMemberScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Report Member',
    description: 'Report a member.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
