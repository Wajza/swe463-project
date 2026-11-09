import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/models/skill_listing.dart';

import 'category_icon.dart';
import 'info_card.dart';
import 'info_tile.dart';

/// The full description of a listing, shared by its preview and details pages.
class ListingSummary extends StatelessWidget {
  const ListingSummary({required this.listing, super.key});

  final SkillListing listing;

  String get _format => [
    listing.onlineOnly ? 'Online' : 'In person or online',
    if (listing.womenOnly) 'Women only',
  ].join(' • ');

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
            value: '${listing.city} • $_format',
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    ],
  );
}
