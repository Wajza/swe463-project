import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class CreateGroupTradeScreen extends StatelessWidget {
  const CreateGroupTradeScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Create Group Trade',
    description: 'Create a group skill exchange.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
