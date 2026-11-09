import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

import 'app_page.dart';

/// A centred message with next steps: confirmations and full-screen states.
class StatusPage extends StatelessWidget {
  const StatusPage({
    required this.title,
    required this.message,
    this.pageTitle = '',
    this.icon = Icons.check_circle_outline,
    this.actions = const [],
    this.showBackButton = true,
    this.visual,
    super.key,
  });

  final String pageTitle;
  final String title;
  final String message;
  final IconData icon;
  final List<Widget> actions;
  final bool showBackButton;
  final Widget? visual;

  @override
  Widget build(BuildContext context) => AppPage(
    title: pageTitle,
    showBackButton: showBackButton,
    footer: actions,
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            visual ??
                CircleAvatar(
                  radius: 44,
                  backgroundColor: context.colors.primaryContainer,
                  child: Icon(
                    icon,
                    size: 42,
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}
