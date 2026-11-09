import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/category_config.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/saved_search.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/notification_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/category_icon.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/search_field.dart';
import 'package:souq_skills/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _search(BuildContext context, SavedSearch criteria) =>
      context.open(AppRoutes.searchResults, args: criteria);

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final profile = ProfileService();
      final unread = NotificationService().unreadCount();
      final listings = ListingService().discover(
        SavedSearch(
          onlineOnly: profile.settings.onlineOnly,
          womenOnly: profile.settings.womenOnly,
        ),
      );
      return AppPage(
        title: 'Home',
        actions: [
          IconButton(
            tooltip: 'Saved skills',
            onPressed: () => context.open(AppRoutes.savedSkills),
            icon: const Icon(Icons.favorite_border),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.open(AppRoutes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_none),
            ),
          ),
        ],
        children: [
          Text(
            'Hello, ${profile.currentUser.name.split(' ').first}',
            style: context.textStyles.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          SearchField(
            onSubmitted: (query) => _search(context, SavedSearch(query: query)),
          ),
          const SectionHeader(title: 'Categories'),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final category in CategoryConfig.names)
                  _CategoryShortcut(
                    category: category,
                    onTap: () =>
                        _search(context, SavedSearch(category: category)),
                  ),
              ],
            ),
          ),
          const SectionHeader(title: 'Quick links'),
          const _QuickLinks(),
          const SectionHeader(title: 'Skills for you'),
          if (listings.isEmpty)
            const EmptyState(
              title: 'No listings match',
              message: 'Try changing your discovery preferences in Settings.',
            ),
          ...listings.map((listing) => ListingCard(listing: listing)),
        ],
      );
    },
  );
}

class _CategoryShortcut extends StatelessWidget {
  const _CategoryShortcut({required this.category, required this.onTap});

  final String category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: SizedBox(
      width: 82,
      child: Column(
        spacing: 6,
        children: [
          CategoryIcon(category: category),
          Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  static const _links = <(String, IconData, String)>[
    ('My trades', Icons.swap_horiz, AppRoutes.myTrades),
    ('Group trades', Icons.groups_outlined, AppRoutes.groupTrades),
    ('Saved searches', Icons.bookmark_border, AppRoutes.savedSearches),
    (
      'Search alerts',
      Icons.notifications_active_outlined,
      AppRoutes.searchAlerts,
    ),
    ('Safety', Icons.shield_outlined, AppRoutes.safety),
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      for (final (label, icon, route) in _links)
        ActionChip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          onPressed: () => context.open(route),
        ),
    ],
  );
}
