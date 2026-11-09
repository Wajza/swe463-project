import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class TradeStatusScreen extends StatelessWidget {
  const TradeStatusScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Trade Status',
    description: 'Current exchange status.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
