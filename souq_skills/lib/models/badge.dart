class Badge {
  const Badge({
    required this.title,
    required this.description,
    required this.iconName,
    this.isEarned = false,
    this.progress = 0,
    this.target = 1,
  });

  final String title;
  final String description;
  final String iconName;
  final bool isEarned;
  final int progress;
  final int target;
}
