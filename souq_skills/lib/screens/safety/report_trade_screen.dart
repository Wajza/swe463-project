import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ReportTradeScreen extends StatelessWidget {
  const ReportTradeScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Report Trade',
    description: 'Report a trade problem.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
