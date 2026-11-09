import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/badge_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/services/trade_service.dart';
import 'package:souq_skills/services/wallet_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/badge_strip.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/profile_header.dart';
import 'package:souq_skills/widgets/rating_summary.dart';
import 'package:souq_skills/widgets/review_card.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/settings_group.dart';
import 'package:souq_skills/widgets/settings_tile.dart';
import 'package:souq_skills/widgets/stat_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _me = User.currentUserId;
  static const _links = <(String, IconData, String)>[
    ('My listings', Icons.storefront_outlined, AppRoutes.myListings),
    ('My skills', Icons.auto_awesome_outlined, AppRoutes.mySkills),
    ('My trades', Icons.swap_horiz, AppRoutes.myTrades),
    ('Trade history', Icons.history, AppRoutes.tradeHistory),
    ('Group trades', Icons.groups_outlined, AppRoutes.groupTrades),
    ('Saved skills', Icons.favorite_border, AppRoutes.savedSkills),
    ('Account details', Icons.person_outline, AppRoutes.accountDetails),
  ];

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final reviews = ReviewService();
      final badges = BadgeService().badges();
      final earned = badges.where((badge) => badge.isEarned).length;
      final latest = reviews.latestForCurrentUser(limit: 3);
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
          ProfileHeader(user: ProfileService().currentUser),
          const SizedBox(height: 16),
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
                value: '${TradeService().completedCount()}',
                label: 'Trades',
                icon: Icons.swap_horiz,
                onTap: () => context.open(AppRoutes.tradeHistory),
              ),
              StatTile(
                value: '${WalletService().balance}',
                label: 'Credits',
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => context.resetTo(AppRoutes.wallet),
              ),
            ],
          ),
          SectionHeader(
            title: 'Badges ($earned/${badges.length})',
            actionLabel: 'See all',
            onAction: () => context.open(AppRoutes.badges),
          ),
          BadgeStrip(badges: badges),
          SectionHeader(
            title: 'Ratings and reviews',
            actionLabel: 'See all',
            onAction: () => context.open(AppRoutes.reviews),
          ),
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
