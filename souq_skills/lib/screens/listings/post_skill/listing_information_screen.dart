import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ListingInformationScreen extends StatelessWidget {
  const ListingInformationScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Listing Information',
    description: 'Add availability and exchange preferences.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
