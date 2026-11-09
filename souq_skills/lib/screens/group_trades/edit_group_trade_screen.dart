import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class EditGroupTradeScreen extends StatelessWidget {
  const EditGroupTradeScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Edit Group Trade',
    description: 'Edit your group exchange.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
