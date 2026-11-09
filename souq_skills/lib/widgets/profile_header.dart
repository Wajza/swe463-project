import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/models/user.dart';

import 'user_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      UserAvatar(initials: user.initials, radius: 42),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 6,
        children: [
          Flexible(
            child: Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (user.isVerified)
            Icon(Icons.verified, size: 20, color: context.colors.primary),
        ],
      ),
      if (user.username.isNotEmpty) Text('@${user.username}'),
      if (user.city.isNotEmpty) Text(user.city),
      if (user.bio.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(user.bio, textAlign: TextAlign.center),
      ],
    ],
  );
}
