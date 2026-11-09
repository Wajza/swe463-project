import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/achievement_badge.dart';

import 'badge_medal.dart';

class BadgeCard extends StatelessWidget {
  const BadgeCard({required this.badge, super.key});

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: () => context.open(AppRoutes.badgeDetails, args: badge.id),
      leading: BadgeMedal(badge: badge, radius: 24),
      title: Text(badge.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(badge.requirement),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: badge.completion, minHeight: 5),
        ],
      ),
      trailing: Text('${badge.cappedProgress}/${badge.target}'),
    ),
  );
}
