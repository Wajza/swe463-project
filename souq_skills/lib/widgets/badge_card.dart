import 'package:flutter/material.dart';
import 'package:souq_skills/models/achievement_badge.dart';

import 'badge_medal.dart';

class BadgeCard extends StatelessWidget {
  const BadgeCard({required this.badge, super.key});

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: BadgeMedal(badge: badge, radius: 24),
      title: Text(badge.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(badge.isEarned ? badge.description : badge.requirement),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: badge.completion, minHeight: 5),
        ],
      ),
      trailing: Text('${badge.cappedProgress}/${badge.target}'),
    ),
  );
}
