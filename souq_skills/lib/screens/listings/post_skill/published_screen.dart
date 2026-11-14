import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/souq_button.dart';

/// Shown once a new solo listing has been saved, with what was published
/// and where to go next.
class PublishedScreen extends StatelessWidget {
  const PublishedScreen({required this.listingId, super.key});

  final String listingId;

  @override
  Widget build(BuildContext context) => LiveEntity<SkillListing>(
    find: () => ListingService().byId(listingId),
    builder: (context, listing) => AppPage(
      title: 'Published',
      showBackButton: false,
      action: SouqButton(
        label: 'View listing',
        onPressed: () =>
            context.replaceWith(AppRoutes.listingDetails, args: listing.id),
      ),
      children: [
        const SizedBox(height: 24),
        Center(
          child: CircleAvatar(
            radius: 52,
            backgroundColor: context.colors.primaryContainer,
            child: Icon(
              Icons.check,
              size: 48,
              color: context.colors.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Your skill is out there',
          textAlign: TextAlign.center,
          style: context.textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your listing is ready to be discovered.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: Icon(Icons.auto_awesome, color: context.colors.primary),
            title: Text(listing.title),
            subtitle: Text(
              listing.wants.isEmpty
                  ? 'Offering ${listing.offers}'
                  : 'Looking for ${listing.wants}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                context.replaceWith(AppRoutes.listingDetails, args: listing.id),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.resetTo(AppRoutes.postSkill),
          child: const Text('Post another skill'),
        ),
        TextButton(
          onPressed: () => context.resetTo(AppRoutes.home),
          child: const Text('Back to home'),
        ),
      ],
    ),
  );
}
