import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/services/review_service.dart';

import 'star_rating.dart';

class RatingSummary extends StatelessWidget {
  const RatingSummary({required this.memberId, this.onTap, super.key});

  final String memberId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: ReviewService.loadStates,
    builder: (context, _, _) {
      final service = ReviewService();
      final hidden = service.isHidden(memberId);
      final average = service.averageRatingOf(memberId);
      final count = service.receivedBy(memberId).length;
      final status = service.stateOf(memberId).status;
      final loading = count == 0 && status == ReviewsLoadStatus.loading;
      return Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              spacing: 16,
              children: [
                Text(
                  hidden ? '–' : AppFormatters.rating(average),
                  style: context.textStyles.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      StarRating(rating: average ?? 0, size: 22),
                      Text(switch ((hidden, loading, count)) {
                        (true, _, _) => 'Ratings are private',
                        (_, true, _) => 'Loading ratings…',
                        (_, _, 0) when status == ReviewsLoadStatus.failed =>
                          'Ratings could not be loaded',
                        (_, _, 0) => 'No ratings yet',
                        (_, _, 1) => '1 rating received',
                        _ => '$count ratings received',
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
