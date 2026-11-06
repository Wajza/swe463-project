import '../models/listing_review.dart';

// Temporary samples keyed by listing ID.
const Map<String, List<ListingReview>> demoListingReviews = {
  'demo-brand-design': [
    ListingReview(
      reviewerName: 'Reem M.',
      stars: 5,
      comment: 'Lama made branding feel simple and practical. '
          'I left with a real direction for my bakery.',
    ),
    ListingReview(
      reviewerName: 'Fahad S.',
      stars: 5,
      comment: 'Everything was exactly as agreed. Great experience.',
    ),
  ],
};
