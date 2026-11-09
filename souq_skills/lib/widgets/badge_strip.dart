import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/achievement_badge.dart';

import 'badge_medal.dart';

class BadgeStrip extends StatelessWidget {
  const BadgeStrip({required this.badges, super.key});

  final List<AchievementBadge> badges;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 112,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: badges.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final badge = badges[index];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.open(AppRoutes.badges),
          child: SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                spacing: 6,
                children: [
                  BadgeMedal(badge: badge),
                  Text(
                    badge.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
