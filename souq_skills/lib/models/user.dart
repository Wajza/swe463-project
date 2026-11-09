import 'identifiable.dart';

class User implements Identifiable {
  const User({
    required this.id,
    required this.name,
    this.username = '',
    this.city = '',
    this.bio = '',
    this.phone = '',
    this.isVerified = false,
    this.skillsOffered = const [],
    this.skillsWanted = const [],
    this.availability = '',
  });

  static const currentUserId = 'me';

  @override
  final String id;
  final String name;
  final String username;
  final String city;
  final String bio;
  final String phone;
  final bool isVerified;
  final List<String> skillsOffered;
  final List<String> skillsWanted;
  final String availability;

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  User copyWith({
    String? name,
    String? username,
    String? city,
    String? bio,
    String? phone,
    bool? isVerified,
    List<String>? skillsOffered,
    List<String>? skillsWanted,
    String? availability,
  }) => User(
    id: id,
    name: name ?? this.name,
    username: username ?? this.username,
    city: city ?? this.city,
    bio: bio ?? this.bio,
    phone: phone ?? this.phone,
    isVerified: isVerified ?? this.isVerified,
    skillsOffered: skillsOffered ?? this.skillsOffered,
    skillsWanted: skillsWanted ?? this.skillsWanted,
    availability: availability ?? this.availability,
  );
}
