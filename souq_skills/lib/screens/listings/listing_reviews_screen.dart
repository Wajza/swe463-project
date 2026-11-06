import 'package:flutter/material.dart';

import '../../data/demo_listing_reviews.dart';
import '../../main.dart';
import '../../models/listing_review.dart';
import '../../models/skill_listing.dart';

class ListingReviewsSection extends StatelessWidget {
  const ListingReviewsSection({
    super.key,
    required this.listing,
  });

  final SkillListing listing;

  @override
  Widget build(BuildContext context) {
    final reviews =
        demoListingReviews[listing.id] ?? const <ListingReview>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'What learners say',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ListingReviewsScreen(listing: listing),
                  ),
                );
              },
              child: Text(
                listing.reviewCount == 0
                    ? 'Reviews'
                    : '${listing.reviewCount} reviews',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          const _EmptyReviews()
        else
          _ReviewCard(review: reviews.first),
      ],
    );
  }
}

class ListingReviewsScreen extends StatelessWidget {
  const ListingReviewsScreen({
    super.key,
    required this.listing,
  });

  final SkillListing listing;

  @override
  Widget build(BuildContext context) {
    final reviews =
        demoListingReviews[listing.id] ?? const <ListingReview>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: souqMint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_outline, color: souqGreen),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text('Feedback for ${listing.title}.'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (reviews.isEmpty)
                  const _EmptyReviews()
                else ...[
                  Text(
                    'Showing ${reviews.length} of '
                    '${listing.reviewCount} reviews',
                  ),
                  const SizedBox(height: 16),
                  for (final review in reviews) ...[
                    _ReviewCard(review: review),
                    const SizedBox(height: 14),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ListingReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: souqGreen,
                  child: Text(
                    review.initials,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    review.reviewerName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              label: '${review.stars} out of 5 stars',
              excludeSemantics: true,
              child: Text(
                List.filled(review.stars, '★').join(),
                style: const TextStyle(
                  color: souqGold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 36, color: souqGreen),
          SizedBox(height: 12),
          Text('No reviews yet'),
          SizedBox(height: 6),
          Text(
            'Reviews will appear here after completed skill exchanges.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
