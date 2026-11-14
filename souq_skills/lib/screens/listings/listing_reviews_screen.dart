import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/rating_summary.dart';
import 'package:souq_skills/widgets/review_card.dart';

/// Every rating the owner of a listing has received, from the listing's
/// "See all" link. Ratings belong to members, not to single listings, so
/// this is the same feedback their public profile shows.
class ListingReviewsScreen extends StatefulWidget {
  const ListingReviewsScreen({required this.listingId, super.key});

  final String listingId;

  @override
  State<ListingReviewsScreen> createState() => _ListingReviewsScreenState();
}

class _ListingReviewsScreenState extends State<ListingReviewsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetched again on each visit, after the first frame; does nothing
    // offline.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final listing = ListingService().byId(widget.listingId);
    if (listing == null) return;
    await ReviewService().refreshReviews([listing.ownerId], refresh: true);
  }

  @override
  Widget build(BuildContext context) => LiveEntity<SkillListing>(
    find: () => ListingService().byId(widget.listingId),
    builder: (context, listing) => ValueListenableBuilder(
      valueListenable: ReviewService.loadStates,
      builder: (context, _, _) {
        final service = ReviewService();
        final ownerId = listing.ownerId;
        final load = service.stateOf(ownerId);
        final hidden = service.isHidden(ownerId);
        final reviews = service.receivedBy(ownerId);
        final loading =
            reviews.isEmpty &&
            (load.status == ReviewsLoadStatus.loading ||
                load.status == ReviewsLoadStatus.notLoaded);
        return AppPage(
          title: 'Reviews',
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  color: context.colors.primaryContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.star_outline,
                      color: context.colors.onPrimaryContainer,
                    ),
                    title: Text(listing.title),
                    subtitle: Text(
                      'Feedback for ${MemberService().nameOf(ownerId)} from '
                      'their completed exchanges.',
                    ),
                  ),
                ),
                RatingSummary(memberId: ownerId),
                if (load.status == ReviewsLoadStatus.failed)
                  ListingsLoadError(
                    title: 'Could not load reviews',
                    message: load.message,
                    onRetry: _refresh,
                  ),
                if (hidden)
                  const EmptyState(
                    title: 'Reviews are private',
                    message: 'This member keeps their ratings private.',
                    icon: Icons.lock_outline,
                  )
                else if (loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (reviews.isEmpty &&
                    load.status != ReviewsLoadStatus.failed)
                  const EmptyState(
                    title: 'No reviews yet',
                    message:
                        'Reviews appear here after completed skill '
                        'exchanges.',
                    icon: Icons.rate_review_outlined,
                  )
                else ...[
                  if (reviews.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        reviews.length == 1
                            ? '1 review'
                            : '${reviews.length} reviews',
                        style: context.textStyles.bodySmall,
                      ),
                    ),
                  ...reviews.map((review) => ReviewCard(review: review)),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}
