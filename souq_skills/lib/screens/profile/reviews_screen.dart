import 'package:flutter/material.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/choice_chip_row.dart';
import 'package:souq_skills/widgets/empty_state.dart';
import 'package:souq_skills/widgets/listings_load_error.dart';
import 'package:souq_skills/widgets/live_view.dart';
import 'package:souq_skills/widgets/rating_summary.dart';
import 'package:souq_skills/widgets/review_card.dart';

enum _ReviewTab {
  received('Received'),
  given('Given by me');

  const _ReviewTab(this.label);
  final String label;
}

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static const _me = User.currentUserId;

  _ReviewTab _tab = _ReviewTab.received;

  @override
  void initState() {
    super.initState();
    // Fetched again on each visit, after the first frame; does nothing
    // offline.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() =>
      ReviewService().refreshReviews(const [_me], refresh: true);

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) => ValueListenableBuilder(
      valueListenable: ReviewService.loadStates,
      builder: (context, _, _) {
        final service = ReviewService();
        final load = service.stateOf(_me);
        final reviews = _tab == _ReviewTab.received
            ? service.receivedBy(_me)
            : service.givenByCurrentUser();
        return AppPage(
          title: 'Ratings and reviews',
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const RatingSummary(memberId: _me),
                ChoiceChipRow<_ReviewTab>(
                  options: _ReviewTab.values,
                  selected: _tab,
                  labelOf: (tab) => tab.label,
                  onSelected: (tab) => setState(() => _tab = tab),
                ),
                const SizedBox(height: 14),
                if (load.status == ReviewsLoadStatus.failed)
                  ListingsLoadError(
                    title: 'Could not load your ratings',
                    message: load.message,
                    onRetry: _refresh,
                  ),
                if (reviews.isEmpty &&
                    (load.status == ReviewsLoadStatus.loading ||
                        load.status == ReviewsLoadStatus.notLoaded))
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (reviews.isEmpty &&
                    load.status != ReviewsLoadStatus.failed)
                  const EmptyState(
                    title: 'No reviews yet',
                    message: 'Ratings appear here after completed exchanges.',
                    icon: Icons.star_outline,
                  ),
                ...reviews.map((review) => ReviewCard(review: review)),
              ],
            ),
          ),
        );
      },
    ),
  );
}
