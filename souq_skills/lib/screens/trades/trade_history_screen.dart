import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class TradeHistoryScreen extends StatelessWidget {
  const TradeHistoryScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Trade History',
    description: 'Pending, accepted, completed, and declined trades.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
