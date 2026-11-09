import 'identifiable.dart';

class Review implements Identifiable {
  const Review({
    required this.id,
    required this.authorId,
    required this.subjectId,
    required this.comment,
    required this.rating,
    required this.date,
    this.contextId = '',
    this.skillTitle = '',
  });

  @override
  final String id;
  final String authorId;
  final String subjectId;
  final String comment;
  final double rating;
  final DateTime date;
  final String contextId;
  final String skillTitle;

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'subjectId': subjectId,
    'comment': comment,
    'rating': rating,
    'date': date.toIso8601String(),
    'contextId': contextId,
    'skillTitle': skillTitle,
  };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json['id'] as String,
    authorId: json['authorId'] as String,
    subjectId: json['subjectId'] as String,
    comment: json['comment'] as String,
    rating: (json['rating'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    contextId: json['contextId'] as String,
    skillTitle: json['skillTitle'] as String,
  );
}
