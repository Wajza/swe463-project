import 'package:flutter/material.dart';
import 'package:souq_skills/widgets/article_page.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ArticlePage(
    title: 'Terms',
    sections: [
      ArticleSection(
        'Using Souq Skills',
        'You must give accurate information and use the app respectfully.',
      ),
      ArticleSection(
        'Skill exchanges',
        'Trades are agreements between members. Souq Skills connects members '
            'but does not provide the skills being exchanged.',
      ),
      ArticleSection(
        'Credits',
        'Skill credits have no cash value and cannot be exchanged for money.',
      ),
      ArticleSection(
        'Account closure',
        'You can delete your account at any time from Settings.',
      ),
    ],
  );
}
