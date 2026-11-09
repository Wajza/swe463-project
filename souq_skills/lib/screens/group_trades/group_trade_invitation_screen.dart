import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class GroupTradeInvitationScreen extends StatelessWidget {
  const GroupTradeInvitationScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Group Trade Invitation',
    description: 'Review a group trade invitation.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
