import 'package:flutter/material.dart';
import 'package:souq_skills/core/navigation.dart';

import 'souq_button.dart';
import 'status_page.dart';

/// Asks the user to confirm that a trade or group trade has finished.
class CompletionConfirmPage extends StatelessWidget {
  const CompletionConfirmPage({
    required this.pageTitle,
    required this.title,
    required this.summary,
    required this.credits,
    required this.onConfirm,
    super.key,
  });

  final String pageTitle;
  final String title;
  final String summary;
  final int credits;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => StatusPage(
    pageTitle: pageTitle,
    icon: Icons.task_alt,
    title: title,
    message: '$summary\n\nConfirming adds $credits credits to your wallet.',
    actions: [
      SouqButton(label: 'Confirm completion', onPressed: onConfirm),
      SouqButton(
        label: 'Not yet',
        outlined: true,
        onPressed: () => context.back(),
      ),
    ],
  );
}
