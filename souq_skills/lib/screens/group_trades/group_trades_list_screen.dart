import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class GroupTradesListScreen extends StatelessWidget {
  const GroupTradesListScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Group Trades List',
    description: 'Browse group exchanges.',
    icon: Icons.groups_outlined,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
