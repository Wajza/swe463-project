import 'package:flutter/material.dart';
import 'package:souq_skills/widgets/article_page.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) => const ArticlePage(
    title: 'Community guidelines',
    sections: [
      ArticleSection('Be respectful', 'Treat every member with courtesy.'),
      ArticleSection(
        'Be honest',
        'Describe your skills accurately and keep the commitments you make.',
      ),
      ArticleSection(
        'Stay safe',
        'Meet in public places and report anything that makes you uneasy.',
      ),
      ArticleSection(
        'Rate fairly',
        'Share ratings that reflect your real experience of the exchange.',
      ),
    ],
  );
}
