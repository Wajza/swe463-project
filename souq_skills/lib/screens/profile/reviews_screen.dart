import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shared/screen_shell.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});
  @override Widget build(BuildContext context) => ScreenShell(
    title: 'Reviews',
    description: 'Reviews from completed exchanges.',
    icon: Icons.auto_awesome,
    actions: [ScreenAction(label: 'Continue', onPressed: () => Navigator.maybePop(context))],
  );
}
