import 'package:flutter/material.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/choice_chip_row.dart';
import 'package:souq_skills/widgets/empty_state.dart';
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
  _ReviewTab _tab = _ReviewTab.received;

  @override
  Widget build(BuildContext context) => LiveView(
    builder: (context) {
      final service = ReviewService();
      final reviews = _tab == _ReviewTab.received
          ? service.receivedBy(User.currentUserId)
          : service.givenByCurrentUser();
      return AppPage(
        title: 'Ratings and reviews',
        children: [
          const RatingSummary(memberId: User.currentUserId),
          ChoiceChipRow<_ReviewTab>(
            options: _ReviewTab.values,
            selected: _tab,
            labelOf: (tab) => tab.label,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 14),
          if (reviews.isEmpty)
            const EmptyState(
              title: 'No reviews yet',
              message: 'Ratings appear here after completed exchanges.',
              icon: Icons.star_outline,
            ),
          ...reviews.map((review) => ReviewCard(review: review)),
        ],
      );
    },
  );
}
