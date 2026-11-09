import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class RateTradeScreen extends StatelessWidget {
  const RateTradeScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Rate Trade',
    description: 'Rate and review the exchange.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
