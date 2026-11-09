import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/live_view.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final listings = ListingService().mine();
      final addButton = FloatingActionButton(
        tooltip: 'Post a skill',
        onPressed: () => context.open(AppRoutes.skillCategory),
        child: const Icon(Icons.add),
      );
      return AppPage(
        emptyState: const EmptyState(
          title: 'No listings yet',
          message: 'Post your first skill to start trading.',
        ),
        title: 'My listings',
        floatingActionButton: addButton,
        children: [for (final item in listings) ListingCard(listing: item)],
      );
    },
  );
}
