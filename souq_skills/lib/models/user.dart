import 'identifiable.dart';

class User implements Identifiable {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
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
  final String firstName;
  final String lastName;
  final String username;
  final String city;
  final String bio;
  final String phone;
  final bool isVerified;
  final List<String> skillsOffered;
  final List<String> skillsWanted;
  final String availability;

  String get name => '$firstName $lastName';

  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  User copyWith({
    String? firstName,
    String? lastName,
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
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    username: username ?? this.username,
    city: city ?? this.city,
    bio: bio ?? this.bio,
    phone: phone ?? this.phone,
    isVerified: isVerified ?? this.isVerified,
    skillsOffered: skillsOffered ?? this.skillsOffered,
    skillsWanted: skillsWanted ?? this.skillsWanted,
    availability: availability ?? this.availability,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'username': username,
    'city': city,
    'bio': bio,
    'phone': phone,
    'isVerified': isVerified,
    'skillsOffered': skillsOffered,
    'skillsWanted': skillsWanted,
    'availability': availability,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    username: json['username'] as String,
    city: json['city'] as String,
    bio: json['bio'] as String,
    phone: json['phone'] as String,
    isVerified: json['isVerified'] as bool,
    skillsOffered: List<String>.from(json['skillsOffered'] as List),
    skillsWanted: List<String>.from(json['skillsWanted'] as List),
    availability: json['availability'] as String,
  );
}
