import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ListingPreviewScreen extends StatelessWidget {
  const ListingPreviewScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Listing Preview',
    description: 'Preview your listing before publishing.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
