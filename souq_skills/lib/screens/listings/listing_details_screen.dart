import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ListingDetailsScreen extends StatelessWidget {
  const ListingDetailsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Listing Details',
    description: 'View listing information, availability, and reviews.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
