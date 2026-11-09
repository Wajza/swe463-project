import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_colors.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/badge_config.dart';
import 'package:souq_skills/models/achievement_badge.dart';

class BadgeMedal extends StatelessWidget {
  const BadgeMedal({required this.badge, this.radius = 28, super.key});

  final AchievementBadge badge;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = badge.isEarned ? souqGold : context.colors.outline;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: .18),
      child: Icon(
        badge.isEarned ? BadgeConfig.iconFor(badge.id) : Icons.lock_outline,
        color: color,
        size: radius,
      ),
    );
  }
}
