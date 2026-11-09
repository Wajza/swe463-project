import 'package:flutter/material.dart';
import 'package:souq_skills/services/badge_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/badge_card.dart';
import 'package:souq_skills/widgets/live_view.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) => AppPage(
      title: 'Badges',
      children: [
        for (final badge in BadgeService().badges()) BadgeCard(badge: badge),
      ],
    ),
  );
}
