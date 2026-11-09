import 'listing_kind.dart';

/// The selections made on the post form, for a solo listing or a group trade.
class SkillPost {
  const SkillPost({
    required this.kind,
    required this.city,
    required this.availability,
    this.category,
    this.skills = const [],
    this.wants,
    this.sessionsMinutes = 60,
    this.onlineOnly = false,
    this.womenOnly = false,
  });

  final ListingKind kind;
  final String? category;
  final List<String> skills;
  final String? wants;
  final String availability;
  final int sessionsMinutes;
  final String city;
  final bool onlineOnly;
  final bool womenOnly;

  bool get isGroup => kind == ListingKind.group;

  SkillPost copyWith({
    ListingKind? kind,
    String? category,
    List<String>? skills,
    String? wants,
    String? availability,
    int? sessionsMinutes,
    String? city,
    bool? onlineOnly,
    bool? womenOnly,
  }) => SkillPost(
    kind: kind ?? this.kind,
    category: category ?? this.category,
    skills: skills ?? this.skills,
    wants: wants ?? this.wants,
    availability: availability ?? this.availability,
    sessionsMinutes: sessionsMinutes ?? this.sessionsMinutes,
    city: city ?? this.city,
    onlineOnly: onlineOnly ?? this.onlineOnly,
    womenOnly: womenOnly ?? this.womenOnly,
  );
}
