class ListingReview {
  const ListingReview({
    required this.reviewerName,
    required this.stars,
    required this.comment,
  }) : assert(stars >= 1 && stars <= 5);

  final String reviewerName;
  final int stars;
  final String comment;

  String get initials {
    final parts = reviewerName.trim().split(RegExp(r'\s+'));
    if (parts.first.isEmpty) return '?';

    final first = String.fromCharCode(parts.first.runes.first);
    final last = parts.length > 1
        ? String.fromCharCode(parts.last.runes.first)
        : '';

    return '$first$last'.toUpperCase();
  }
}
