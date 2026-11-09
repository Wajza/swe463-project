import 'package:flutter/material.dart';
import 'package:souq_skills/models/achievement_badge.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/badge_service.dart';
import 'package:souq_skills/widgets/badge_medal.dart';
import 'package:souq_skills/widgets/status_page.dart';

class BadgeDetailsScreen extends StatelessWidget {
  const BadgeDetailsScreen({required this.badgeId, super.key});

  final String badgeId;

  @override
  Widget build(BuildContext context) => LiveEntity<AchievementBadge>(
    find: () => BadgeService().byId(badgeId),
    builder: (context, badge) => StatusPage(
      pageTitle: 'Badge',
      visual: BadgeMedal(badge: badge, radius: 48),
      title: badge.title,
      message:
          '${badge.description}\n\n'
          '${badge.isEarned ? 'Earned' : 'Requirement: ${badge.requirement}'}\n'
          'Progress: ${badge.cappedProgress} of ${badge.target}',
    ),
  );
}
