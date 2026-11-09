import 'identifiable.dart';

class AchievementBadge implements Identifiable {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.requirement,
    required this.progress,
    required this.target,
  });

  @override
  final String id;
  final String title;
  final String description;
  final String requirement;
  final int progress;
  final int target;

  bool get isEarned => progress >= target;
  int get cappedProgress => progress.clamp(0, target);
  double get completion => cappedProgress / target;
}
