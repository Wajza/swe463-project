import 'package:flutter/material.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) => StatusPage(
    pageTitle: 'Offline',
    icon: Icons.cloud_off_outlined,
    title: 'You are offline',
    message: 'Check your connection and try again.',
    actions: [
      SouqButton(
        label: 'Try again',
        icon: Icons.refresh,
        onPressed: () => context.back(),
      ),
    ],
  );
}
