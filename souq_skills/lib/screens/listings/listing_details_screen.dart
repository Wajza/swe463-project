import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/proposal_request.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/listing_summary.dart';
import 'package:souq_skills/widgets/member_tile.dart';
import 'package:souq_skills/widgets/review_card.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/souq_button.dart';

class ListingDetailsScreen extends StatelessWidget {
  const ListingDetailsScreen({required this.listingId, super.key});

  final String listingId;

  @override
  Widget build(BuildContext context) => LiveEntity<SkillListing>(
    find: () => ListingService().byId(listingId),
    builder: (context, listing) {
      final isMine = ListingService().isMine(listing);
      final reviews = ReviewService().receivedBy(listing.ownerId).take(2);
      return AppPage(
        title: 'Listing details',
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () =>
                context.open(AppRoutes.shareListing, args: listing.id),
            icon: const Icon(Icons.share_outlined),
          ),
          if (!isMine)
            IconButton(
              tooltip: listing.isSaved ? 'Remove from saved' : 'Save skill',
              onPressed: () => ListingService().toggleSaved(listing.id),
              icon: Icon(
                listing.isSaved ? Icons.favorite : Icons.favorite_border,
              ),
            ),
        ],
        footer: isMine
            ? [
                SouqButton(
                  label: 'Manage listing',
                  onPressed: () =>
                      context.open(AppRoutes.editListing, args: listing.id),
                ),
              ]
            : [
                SouqButton(
                  label: 'Propose a trade',
                  icon: Icons.handshake_outlined,
                  onPressed: () => context.open(
                    AppRoutes.proposalInsideChat,
                    args: ProposalRequest(
                      memberId: listing.ownerId,
                      listingId: listing.id,
                    ),
                  ),
                ),
                SouqButton(
                  label: 'Message member',
                  outlined: true,
                  onPressed: () =>
                      context.open(AppRoutes.chat, args: listing.ownerId),
                ),
              ],
        children: [
          ListingSummary(listing: listing),
          const SectionHeader(title: 'Offered by'),
          MemberTile(memberId: listing.ownerId),
          if (reviews.isNotEmpty) const SectionHeader(title: 'Reviews'),
          ...reviews.map((review) => ReviewCard(review: review)),
        ],
      );
    },
  );
}
