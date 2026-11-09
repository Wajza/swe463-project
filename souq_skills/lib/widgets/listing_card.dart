import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/review_service.dart';

import 'category_icon.dart';
import 'status_chip.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({required this.listing, super.key});

  final SkillListing listing;

  @override
  Widget build(BuildContext context) {
    final owner = MemberService().nameOf(listing.ownerId);
    final rating = ReviewService().averageRatingOf(listing.ownerId);
    final isMine = ListingService().isMine(listing);
    return Card(
      child: InkWell(
        onTap: () => context.open(AppRoutes.listingDetails, args: listing.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            spacing: 12,
            children: [
              CategoryIcon(category: listing.category),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$owner • ★ ${AppFormatters.rating(rating)} • ${listing.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall,
                    ),
                    Text(
                      '${listing.offers} ⇄ ${listing.wants}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (listing.isPaused)
                const StatusChip(label: 'Paused', tone: StatusTone.waiting)
              else if (!isMine)
                IconButton(
                  tooltip: listing.isSaved ? 'Remove from saved' : 'Save skill',
                  onPressed: () => ListingService().toggleSaved(listing.id),
                  icon: Icon(
                    listing.isSaved ? Icons.favorite : Icons.favorite_border,
                    color: context.colors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
