import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/live_view.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  /// All of the member's listings, paused ones included.
  List<Widget> _buildListings(ListingLoadState load) {
    final service = ListingService();
    if (!service.hasCurrentListings) {
      if (load.isFailed) return const [];
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final mine = service.mine();
    if (mine.isEmpty) {
      return const [
        EmptyState(
          title: 'No listings yet',
          message: 'Post your first skill to start trading.',
        ),
      ];
    }
    return [for (final item in mine) ListingCard(listing: item)];
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) => AppPage(
      title: 'My listings',
      floatingActionButton: FloatingActionButton(
        tooltip: 'Post a skill',
        onPressed: () => context.open(AppRoutes.createListing),
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<ListingLoadState>(
        valueListenable: ListingService.loadState,
        builder: (context, load, _) => RefreshIndicator(
          onRefresh: ListingService().refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              if (load.isFailed)
                ListingsLoadError(
                  message: load.error!,
                  onRetry: ListingService().refresh,
                ),
              ..._buildListings(load),
            ],
          ),
        ),
      ),
    ),
  );
}
