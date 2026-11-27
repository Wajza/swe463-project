import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/badge_service.dart';
import 'package:souq_skills/services/experience_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/services/wallet_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/badge_strip.dart';
import 'package:souq_skills/widgets/experience_card.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/profile_header.dart';
import 'package:souq_skills/widgets/rating_summary.dart';
import 'package:souq_skills/widgets/review_card.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/settings_group.dart';
import 'package:souq_skills/widgets/settings_tile.dart';
import 'package:souq_skills/widgets/skill_chips.dart';
import 'package:souq_skills/widgets/stat_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _me = User.currentUserId;
  static const _links = <(String, IconData, String)>[
    ('My trades', Icons.swap_horiz, AppRoutes.myTrades),
    ('My listings', Icons.storefront_outlined, AppRoutes.myListings),
    ('Group trades', Icons.groups_outlined, AppRoutes.groupTrades),
    ('My skills', Icons.auto_awesome_outlined, AppRoutes.mySkills),
    ('Saved skills', Icons.favorite_border, AppRoutes.savedSkills),
  ];

  @override
  Widget build(BuildContext context) => LiveView(
    alsoListenTo: [ListingService.loadState, ReviewService.loadStates],
    builder: (context) {
      final reviews = ReviewService();
      final badgeService = BadgeService();
      final badges = badgeService.badges();
      final earned = badges.where((badge) => badge.isEarned).length;
      // Never a provisional count while trades or group trades load.
      final badgeCount = badgeService.isLoaded
          ? '$earned/${badges.length}'
          : '…';
      final latest = reviews.latestForCurrentUser(limit: 3);
      final user = ProfileService().currentUser;
      final experience = ExperienceService();
      final status = experience.loadStatus;
      final level = status.isLoading || status.error != null
          ? null
          : experience.current().level;
      return AppPage(
        title: 'Profile',
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.open(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
        children: [
          ProfileHeader(user: user, level: level),
          const SizedBox(height: 16),
          const ExperienceCard(),
          const SizedBox(height: 4),
          Row(
            spacing: 10,
            children: [
              StatTile(
                value: AppFormatters.rating(reviews.averageRatingOf(_me)),
                label: 'Rating',
                icon: Icons.star_outline,
                onTap: () => context.open(AppRoutes.reviews),
              ),
              StatTile(
                value: TradeService().isLoaded
                    ? '${TradeService().completedCount()}'
                    : '…',
                label: 'Trades',
                icon: Icons.swap_horiz,
                onTap: () => context.open(AppRoutes.myTrades),
              ),
              StatTile(
                value: WalletService().isLoaded
                    ? '${WalletService().balance}'
                    : '…',
                label: 'Credits',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => context.resetTo(AppRoutes.wallet),
              ),
            ],
          ),
          SectionHeader(
            title: 'I can share',
            actionLabel: 'Edit',
            onAction: () => context.open(AppRoutes.mySkills),
          ),
          SkillChips(skills: user.skillsOffered),
          const SectionHeader(title: 'I want to learn'),
          SkillChips(skills: user.skillsWanted),
          SectionHeader(title: 'Badges ($badgeCount)'),
          BadgeStrip(badges: badges),
          const SectionHeader(title: 'Ratings and reviews'),
          RatingSummary(
            memberId: _me,
            onTap: () => context.open(AppRoutes.reviews),
          ),
          ...latest.map((review) => ReviewCard(review: review)),
          SettingsGroup(
            title: 'My activity',
            children: [
              for (final (title, icon, route) in _links)
                SettingsTile(
                  title: title,
                  icon: icon,
                  onTap: () => context.open(route),
                ),
            ],
          ),
        ],
      );
    },
  );
}
