import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listing_card.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class SavedSkillsScreen extends StatelessWidget {
  const SavedSkillsScreen({super.key});

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final listings = ListingService().saved();
      return AppPage(
        emptyState: EmptyState(
          title: 'No saved skills',
          message: 'Tap the heart on a listing to find it here.',
          icon: Icons.favorite_border,
          action: SouqButton(
            label: 'Browse skills',
            onPressed: () => context.resetTo(AppRoutes.home),
          ),
        ),
        title: 'Saved skills',
        children: [for (final item in listings) ListingCard(listing: item)],
      );
    },
  );
}
