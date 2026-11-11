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
import 'package:souq_skills/widgets/listings_load_error.dart';
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

  @override
  void initState() {
    super.initState();
    // Home opens after every sign-in and app start, so the shared listings
    // are loaded for whoever is now signed in. After the first frame, as
    // loading updates what other screens show.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ListingService().refresh(),
    );
  }

  void _setCriteria(SearchCriteria criteria) =>
      setState(() => _criteria = criteria);

  bool get _isSearching =>
      _criteria.query.trim().isNotEmpty || _criteria.activeFilterCount > 0;

  List<Widget> _buildResults(ListingLoadState load) {
    final service = ListingService();
    if (!service.hasCurrentListings) {
      // Not loaded for this account yet: nothing else is shown meanwhile.
      if (load.isFailed) return const [];
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final listings = service.discover(_criteria);
    if (listings.isEmpty) {
      return [
        _isSearching || !service.isOnline
            ? const EmptyState(
                title: 'No skills match',
                message: 'Try a different search or change your filters.',
              )
            : const EmptyState(
                title: 'No skills yet',
                message: 'Be the first to post a skill.',
              ),
      ];
    }
    return [for (final listing in listings) ListingCard(listing: listing)];
  }

  Widget _buildList(ListingLoadState load) {
    final profile = ProfileService();
    return RefreshIndicator(
      onRefresh: ListingService().refresh,
      child: ListView(
        // Pulling to refresh works however few listings there are.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Text(
            'Hello, ${profile.currentUser.firstName}',
            style: context.textStyles.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SectionHeader(title: 'Skills for you'),
          if (load.isFailed)
            ListingsLoadError(
              message: load.error!,
              onRetry: ListingService().refresh,
            ),
          ..._buildResults(load),
        ],
      ),
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
            Expanded(
              child: ValueListenableBuilder<ListingLoadState>(
                valueListenable: ListingService.loadState,
                builder: (context, load, _) => _buildList(load),
              ),
            ),
          ],
        ),
      );
    },
  );
}
