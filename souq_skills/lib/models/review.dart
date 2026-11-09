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
}
