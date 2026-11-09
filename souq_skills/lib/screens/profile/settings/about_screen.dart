import 'package:flutter/material.dart';
import 'package:souq_skills/widgets/article_page.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => const ArticlePage(
    title: 'About and policies',
    sections: [
      ArticleSection(
        'Souq Skills 1.0.0',
        'A community marketplace for trading skills without cash.',
      ),
      ArticleSection(
        'Terms',
        'Give accurate information and use the app respectfully. Trades are '
            'agreements between members. Skill credits have no cash value.',
      ),
      ArticleSection(
        'Privacy',
        'We use your phone number, profile, listings, messages and ratings to '
            'run your account and keep members safe. Control your visibility '
            'in Settings.',
      ),
      ArticleSection(
        'Community guidelines',
        'Be respectful and honest, meet in public places, report anything '
            'that makes you uneasy, and rate fairly.',
      ),
    ],
  );
}
