import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Transaction Details',
    description: 'Transaction details.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
