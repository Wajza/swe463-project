/// Describes one finished exchange that the current user can rate.
class RatingRequest {
  const RatingRequest({
    required this.contextId,
    required this.subjectId,
    required this.subjectName,
    required this.skillTitle,
  });

  final String contextId;
  final String subjectId;
  final String subjectName;
  final String skillTitle;
}
