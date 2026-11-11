import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/proposal_request.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/listing_summary.dart';
import 'package:souq_skills/widgets/member_tile.dart';
import 'package:souq_skills/widgets/overflow_menu.dart';
import 'package:souq_skills/widgets/review_card.dart';
import 'package:souq_skills/widgets/save_listing_button.dart';
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
      // Nothing that would reach a blocked member is offered.
      final isBlocked = !isMine && SafetyService().isBlocked(listing.ownerId);
      final reviews = ReviewService().receivedBy(listing.ownerId).take(2);
      return AppPage(
        title: 'Listing details',
        actions: [
          if (!isMine) SaveListingButton(listing: listing),
          OverflowMenu(
            items: [
              MenuAction(
                'Share listing',
                () => context.open(AppRoutes.shareListing, args: listing.id),
              ),
              if (!isMine && !isBlocked)
                MenuAction(
                  'Message member',
                  () => context.open(AppRoutes.chat, args: listing.ownerId),
                ),
            ],
          ),
        ],
        action: isMine
            ? SouqButton(
                label: 'Edit listing',
                onPressed: () =>
                    context.open(AppRoutes.editListing, args: listing.id),
              )
            : isBlocked
            ? null
            : SouqButton(
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
        children: [
          if (isBlocked)
            const Card(
              child: ListTile(
                leading: Icon(Icons.block),
                title: Text('You blocked this member'),
                subtitle: Text('Unblock them to message or propose a trade.'),
              ),
            ),
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
