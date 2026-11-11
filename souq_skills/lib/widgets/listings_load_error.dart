import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

/// Says that the shared listings could not be loaded, with a way to retry.
class ListingsLoadError extends StatelessWidget {
  const ListingsLoadError({
    required this.message,
    required this.onRetry,
    this.title = 'Could not load skills',
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final String title;

  @override
  Widget build(BuildContext context) => Card(
    color: context.colors.errorContainer,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        spacing: 12,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: context.colors.onErrorContainer,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  title,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.onErrorContainer,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(color: context.colors.onErrorContainer),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
