import 'package:flutter/material.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => StatusPage(
    pageTitle: 'Loading',
    visual: const CircularProgressIndicator(),
    title: 'Loading',
    message: 'This will only take a moment.',
    actions: [
      SouqButton(
        label: 'Cancel',
        outlined: true,
        onPressed: () => context.back(),
      ),
    ],
  );
}
