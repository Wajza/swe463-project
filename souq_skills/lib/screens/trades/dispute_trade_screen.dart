import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class DisputeTradeScreen extends StatelessWidget {
  const DisputeTradeScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Dispute Trade',
    description: 'Report a problem with this trade.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
