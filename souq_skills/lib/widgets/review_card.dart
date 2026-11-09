import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/core/formatters.dart';
import 'package:souq_skills/models/review.dart';
import 'package:souq_skills/services/member_service.dart';

import 'star_rating.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, super.key});

  final Review review;

  String get _heading {
    final members = MemberService();
    if (members.isCurrentUser(review.authorId)) {
      return 'You rated ${members.nameOf(review.subjectId)}';
    }
    final author = members.nameOf(review.authorId);
    return members.isCurrentUser(review.subjectId)
        ? '$author rated you'
        : author;
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            _heading,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          StarRating(rating: review.rating),
          if (review.comment.isNotEmpty) Text(review.comment),
          Text(
            [
              if (review.skillTitle.isNotEmpty) review.skillTitle,
              AppFormatters.date(review.date),
            ].join(' • '),
            style: context.textStyles.bodySmall,
          ),
        ],
      ),
    ),
  );
}
