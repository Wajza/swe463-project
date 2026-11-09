import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class TradeDetailsScreen extends StatelessWidget {
  const TradeDetailsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Trade Details',
    description: 'Participants, skills, and schedule.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
