class UserProfile {
  const UserProfile({
    required this.id,
    required this.shownName,
    required this.username,
    required this.city,
    required this.bio,
    this.phoneVerified = false,
    this.hideLocation = false,
  });

  final String id;
  final String shownName;
  final String username;
  final String city;
  final String bio;
  final bool phoneVerified;
  final bool hideLocation;

  String get initials {
    final parts = shownName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    final first = String.fromCharCode(parts.first.runes.first);
    final last = parts.length > 1
        ? String.fromCharCode(parts.last.runes.first)
        : '';

    return '$first$last'.toUpperCase();
  }

  UserProfile copyWith({
    String? shownName,
    String? username,
    String? city,
    String? bio,
    bool? hideLocation,
  }) {
    return UserProfile(
      id: id,
      shownName: shownName ?? this.shownName,
      username: username ?? this.username,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      phoneVerified: phoneVerified,
      hideLocation: hideLocation ?? this.hideLocation,
    );
  }
}
