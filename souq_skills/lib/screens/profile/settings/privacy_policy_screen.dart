import 'package:flutter/material.dart';
import 'package:souq_skills/widgets/article_page.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => const ArticlePage(
    title: 'Privacy policy',
    sections: [
      ArticleSection(
        'What we collect',
        'Your phone number, profile details, listings, messages, and ratings.',
      ),
      ArticleSection(
        'How we use it',
        'To run your account, match you with skills, and keep members safe.',
      ),
      ArticleSection(
        'Your choices',
        'Control your profile and location visibility from Privacy settings.',
      ),
    ],
  );
}
