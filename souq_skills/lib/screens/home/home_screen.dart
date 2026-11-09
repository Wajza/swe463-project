import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/search_criteria.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/notification_service.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/listing_filter_sheet.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/search_field.dart';
import 'package:souq_skills/widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SearchCriteria _criteria = const SearchCriteria();

  void _setCriteria(SearchCriteria criteria) =>
      setState(() => _criteria = criteria);

  Widget _buildList() {
    final profile = ProfileService();
    final listings = ListingService().discover(_criteria);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Text(
          'Hello, ${profile.currentUser.firstName}',
          style: context.textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SectionHeader(title: 'Skills for you'),
        if (listings.isEmpty)
          const EmptyState(
            title: 'No skills match',
            message: 'Try a different search or change your filters.',
          ),
        ...listings.map((listing) => ListingCard(listing: listing)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final unread = NotificationService().unreadCount();
      return AppPage(
        title: 'Home',
        actions: [
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SearchField(
                activeFilterCount: _criteria.activeFilterCount,
                onChanged: (query) =>
                    _setCriteria(_criteria.copyWith(query: query)),
                onFilterTap: () => ListingFilterSheet.show(
                  context,
                  initial: _criteria,
                  onChanged: _setCriteria,
                ),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      );
    },
  );
}
