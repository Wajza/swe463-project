import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/listing_summary.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/step_progress.dart';

class ListingPreviewScreen extends StatelessWidget {
  const ListingPreviewScreen({required this.draft, super.key});

  final SkillListing draft;

  void _publish(BuildContext context) {
    final listing = ListingService().create(draft);
    context.replaceWith(AppRoutes.postConfirmation, args: listing.id);
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Preview listing',
    footer: [
      SouqButton(label: 'Publish', onPressed: () => _publish(context)),
      SouqButton(
        label: 'Make changes',
        outlined: true,
        onPressed: () => context.back(),
      ),
    ],
    children: [
      const StepProgress(step: 4, total: 4),
      ListingSummary(listing: draft),
    ],
  );
}
