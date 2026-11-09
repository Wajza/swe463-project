class User {
  const User({
    required this.name,
    required this.initials,
    this.username = '',
    this.city = '',
    this.bio = '',
    this.phone = '',
    this.isVerified = false,
    this.skillsOffered = const [],
    this.skillsWanted = const [],
    this.availability = '',
  });

  final String name;
  final String initials;
  final String username;
  final String city;
  final String bio;
  final String phone;
  final bool isVerified;
  final List<String> skillsOffered;
  final List<String> skillsWanted;
  final String availability;

  User copyWith({
    String? name, String? initials, String? username, String? city,
    String? bio, String? phone, bool? isVerified,
    List<String>? skillsOffered, List<String>? skillsWanted, String? availability,
  }) => User(
    name: name ?? this.name, initials: initials ?? this.initials,
    username: username ?? this.username, city: city ?? this.city,
    bio: bio ?? this.bio, phone: phone ?? this.phone,
    isVerified: isVerified ?? this.isVerified,
    skillsOffered: skillsOffered ?? this.skillsOffered,
    skillsWanted: skillsWanted ?? this.skillsWanted,
    availability: availability ?? this.availability,
  );
}
