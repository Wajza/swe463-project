import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class TradeCompletionScreen extends StatelessWidget {
  const TradeCompletionScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Trade Completion',
    description: 'Confirm completion of the exchange.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
