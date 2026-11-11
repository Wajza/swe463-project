import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class SavedSkillsScreen extends StatelessWidget {
  const SavedSkillsScreen({super.key});

  List<Widget> _buildSaved(BuildContext context, ListingLoadState load) {
    final service = ListingService();
    // Until loaded for this account, the hearts may be another account's.
    if (!service.hasCurrentListings) {
      if (load.isFailed) return const [];
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final listings = service.saved();
    if (listings.isEmpty) {
      return [
        EmptyState(
          title: 'No saved skills',
          message: 'Tap the heart on a listing to find it here.',
          icon: Icons.favorite_border,
          action: SouqButton(
            label: 'Browse skills',
            onPressed: () => context.resetTo(AppRoutes.home),
          ),
        ),
      ];
    }
    return [for (final item in listings) ListingCard(listing: item)];
  }

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) => AppPage(
      title: 'Saved skills',
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
              ..._buildSaved(context, load),
            ],
          ),
        ),
      ),
    ),
  );
}
