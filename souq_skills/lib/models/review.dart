class Review {
  const Review({
    required this.authorName,
    required this.comment,
    required this.rating,
    this.id = '',
    this.skillTitle = '',
    this.date,
  });

  final String id;
  final String authorName;
  final String comment;
  final double rating;
  final String skillTitle;
  final DateTime? date;
}
