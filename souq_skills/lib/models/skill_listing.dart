import 'identifiable.dart';

class SkillListing implements Identifiable {
  const SkillListing({
    required this.ownerId,
    required this.category,
    this.title = '',
    this.offers = '',
    this.wants = '',
    this.distance = '',
    this.id = '',
    this.description = '',
    this.city = 'Riyadh',
    this.availability = '',
    this.sessionsMinutes = 60,
    this.onlineOnly = false,
    this.womenOnly = false,
    this.isSaved = false,
    this.isPaused = false,
  });

  @override
  final String id;
  final String ownerId;
  final String title;
  final String category;
  final String offers;
  final String wants;
  final String distance;
  final String description;
  final String city;
  final String availability;
  final int sessionsMinutes;
  final bool onlineOnly;
  final bool womenOnly;
  final bool isSaved;
  final bool isPaused;

  SkillListing copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? category,
    String? offers,
    String? wants,
    String? distance,
    String? description,
    String? city,
    String? availability,
    int? sessionsMinutes,
    bool? onlineOnly,
    bool? womenOnly,
    bool? isSaved,
    bool? isPaused,
  }) => SkillListing(
    id: id ?? this.id,
    ownerId: ownerId ?? this.ownerId,
    title: title ?? this.title,
    category: category ?? this.category,
    offers: offers ?? this.offers,
    wants: wants ?? this.wants,
    distance: distance ?? this.distance,
    description: description ?? this.description,
    city: city ?? this.city,
    availability: availability ?? this.availability,
    sessionsMinutes: sessionsMinutes ?? this.sessionsMinutes,
    onlineOnly: onlineOnly ?? this.onlineOnly,
    womenOnly: womenOnly ?? this.womenOnly,
    isSaved: isSaved ?? this.isSaved,
    isPaused: isPaused ?? this.isPaused,
  );
}
