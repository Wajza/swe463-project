import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';

import 'app_page.dart';

class ArticleSection {
  const ArticleSection(this.heading, this.body);

  final String heading;
  final String body;
}

/// Read-only long-form content such as the terms and the privacy policy.
class ArticlePage extends StatelessWidget {
  const ArticlePage({required this.title, required this.sections, super.key});

  final String title;
  final List<ArticleSection> sections;

  @override
  Widget build(BuildContext context) => AppPage(
    title: title,
    children: [
      for (final section in sections) ...[
        Text(section.heading, style: context.textStyles.titleMedium),
        const SizedBox(height: 6),
        Text(section.body, style: const TextStyle(height: 1.5)),
        const SizedBox(height: 20),
      ],
    ],
  );
}
