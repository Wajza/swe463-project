import 'package:flutter/material.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) => StatusPage(
    pageTitle: 'Error',
    icon: Icons.error_outline,
    title: 'Something went wrong',
    message: 'Please try again in a moment.',
    actions: [
      SouqButton(
        label: 'Try again',
        icon: Icons.refresh,
        onPressed: () => context.back(),
      ),
    ],
  );
}
