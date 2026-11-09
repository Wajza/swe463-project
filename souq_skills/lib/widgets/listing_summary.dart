import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/services/listing_service.dart';

import 'category_icon.dart';
import 'info_card.dart';
import 'info_tile.dart';
import 'listing_tags.dart';

/// The full description of a listing.
class ListingSummary extends StatelessWidget {
  const ListingSummary({required this.listing, super.key});

  final SkillListing listing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        spacing: 14,
        children: [
          CategoryIcon(category: listing.category, size: 60),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(listing.category),
              ],
            ),
          ),
        ],
      ),
      if (listing.tags.isNotEmpty) ...[
        const SizedBox(height: 12),
        ListingTags(listing: listing),
      ],
      const SizedBox(height: 16),
      Text(listing.description, style: const TextStyle(height: 1.5)),
      const SizedBox(height: 16),
      InfoCard(
        tiles: [
          InfoTile(
            label: 'Offers',
            value: listing.offers,
            icon: Icons.volunteer_activism_outlined,
          ),
          InfoTile(
            label: 'Wants in exchange',
            value: listing.wants,
            icon: Icons.swap_horiz,
          ),
          InfoTile(
            label: 'Availability',
            value: listing.availability,
            icon: Icons.schedule,
          ),
          InfoTile(
            label: 'Session length',
            value: '${listing.sessionsMinutes} minutes',
            icon: Icons.timer_outlined,
          ),
          InfoTile(
            label: 'Location',
            value: ListingService().locationLabel(listing),
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    ],
  );
}
