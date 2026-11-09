import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Contact Support',
    description: 'Contact the support team.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
