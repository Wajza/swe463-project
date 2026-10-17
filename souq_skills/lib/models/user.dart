class User {
  const User({
    required this.name,
    required this.initials,
    this.isVerified = false,
  });

  final String name;
  final String initials;
  final bool isVerified;
}
