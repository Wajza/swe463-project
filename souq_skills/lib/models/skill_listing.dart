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
    this.ownerId = '',
    this.onlineOnly = false,
    this.womenOnly = false,
    this.description = '',
    this.location = '',
    this.availability = '',
    this.idealTrade = '',
    this.isVerified = false,
    this.reviewCount = 0,
    this.completedTrades = 0,
  });

  final String title;
  final String owner;
  final String category;
  final String offers;
  final String wants;
  final String distance;
  final double rating;
  final String id;
  final String ownerId;
  final bool onlineOnly;
  final bool womenOnly;
  final String description;
  final String location;
  final String availability;
  final String idealTrade;
  final bool isVerified;
  final int reviewCount;
  final int completedTrades;

  SkillListing copyWith({
    String? title,
    String? category,
    String? offers,
    String? wants,
    String? description,
    String? location,
    String? availability,
    bool? onlineOnly,
    bool? womenOnly,
  }) {
    return SkillListing(
      id: id,
      ownerId: ownerId,
      title: title ?? this.title,
      owner: owner,
      category: category ?? this.category,
      offers: offers ?? this.offers,
      wants: wants ?? this.wants,
      distance: distance,
      rating: rating,
      description: description ?? this.description,
      location: location ?? this.location,
      availability: availability ?? this.availability,
      idealTrade: idealTrade,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      womenOnly: womenOnly ?? this.womenOnly,
      isVerified: isVerified,
      reviewCount: reviewCount,
      completedTrades: completedTrades,
    );
  }

  String get ownerInitials {
    final parts = owner.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';

    final first = String.fromCharCode(parts.first.runes.first);
    final last = parts.length > 1
        ? String.fromCharCode(parts.last.runes.first)
        : '';

    return '$first$last'.toUpperCase();
  }
}
