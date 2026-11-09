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
  Widget build(BuildContext context) {
    final service = ReviewService();
    final average = service.averageRatingOf(memberId);
    final count = service.receivedBy(memberId).length;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            spacing: 16,
            children: [
              Text(
                AppFormatters.rating(average),
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
                    Text(
                      count == 0
                          ? 'No ratings yet'
                          : '$count rating${count == 1 ? '' : 's'} received',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
