class SkillListing {
  const SkillListing({
    required this.title,
    required this.owner,
    required this.category,
    required this.offers,
    required this.wants,
    required this.distance,
    required this.rating,
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

  final String id;
  final String title;
  final String owner;
  final String category;
  final String offers;
  final String wants;
  final String distance;
  final double rating;
  final String description;
  final String city;
  final String availability;
  final int sessionsMinutes;
  final bool onlineOnly;
  final bool womenOnly;
  final bool isSaved;
  final bool isPaused;

  SkillListing copyWith({
    String? id, String? title, String? owner, String? category,
    String? offers, String? wants, String? distance, double? rating,
    String? description, String? city, String? availability,
    int? sessionsMinutes, bool? onlineOnly, bool? womenOnly, bool? isSaved,
    bool? isPaused,
  }) => SkillListing(
    id: id ?? this.id, title: title ?? this.title, owner: owner ?? this.owner,
    category: category ?? this.category, offers: offers ?? this.offers,
    wants: wants ?? this.wants, distance: distance ?? this.distance,
    rating: rating ?? this.rating, description: description ?? this.description,
    city: city ?? this.city, availability: availability ?? this.availability,
    sessionsMinutes: sessionsMinutes ?? this.sessionsMinutes,
    onlineOnly: onlineOnly ?? this.onlineOnly, womenOnly: womenOnly ?? this.womenOnly,
    isSaved: isSaved ?? this.isSaved,
    isPaused: isPaused ?? this.isPaused,
  );
}
