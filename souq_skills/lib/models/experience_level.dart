/// A member's experience: total XP, the level it reaches, and progress to
/// the next level.
class ExperienceLevel {
  const ExperienceLevel({
    required this.xp,
    required this.level,
    required this.title,
    required this.levelStartXp,
    required this.nextLevelXp,
    required this.nextTitle,
  });

  final int xp;
  final int level;
  final String title;

  /// The XP at which [level] began, and at which the next level begins.
  final int levelStartXp;
  final int nextLevelXp;

  /// The title of the next level, which may be the same as [title].
  final String nextTitle;

  int get xpIntoLevel => xp - levelStartXp;
  int get xpForLevel => nextLevelXp - levelStartXp;
  int get xpToNextLevel => nextLevelXp - xp;
  double get progress => xpIntoLevel / xpForLevel;
}
