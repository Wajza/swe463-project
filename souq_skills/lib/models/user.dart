class User {
  const User({
    required this.name,
    required this.initials,
    this.isVerified = false,
  });

  final String name;
  final String initials;
  final bool isVerified;

  /// Creates an updated user, preserving fields that are not provided.
  User copyWith({String? name, String? initials, bool? isVerified}) {
    return User(
      name: name ?? this.name,
      initials: initials ?? this.initials,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
