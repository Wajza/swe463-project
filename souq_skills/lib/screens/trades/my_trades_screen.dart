import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class MyTradesScreen extends StatelessWidget {
  const MyTradesScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'My Trades',
    description: 'Your active exchanges.',
    icon: Icons.swap_horiz,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
