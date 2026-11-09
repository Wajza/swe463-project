import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Edit Profile',
    description: 'Edit your bio, skills, and preferences.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
