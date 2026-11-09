import 'identifiable.dart';
import 'listing_tag.dart';

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

  List<ListingTag> get tags => [
    if (onlineOnly) ListingTag.onlineOnly,
    if (womenOnly) ListingTag.womenOnly,
  ];

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'title': title,
    'category': category,
    'offers': offers,
    'wants': wants,
    'distance': distance,
    'description': description,
    'city': city,
    'availability': availability,
    'sessionsMinutes': sessionsMinutes,
    'onlineOnly': onlineOnly,
    'womenOnly': womenOnly,
    'isSaved': isSaved,
    'isPaused': isPaused,
  };

  factory SkillListing.fromJson(Map<String, dynamic> json) => SkillListing(
    id: json['id'] as String,
    ownerId: json['ownerId'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    offers: json['offers'] as String,
    wants: json['wants'] as String,
    distance: json['distance'] as String,
    description: json['description'] as String,
    city: json['city'] as String,
    availability: json['availability'] as String,
    sessionsMinutes: json['sessionsMinutes'] as int,
    onlineOnly: json['onlineOnly'] as bool,
    womenOnly: json['womenOnly'] as bool,
    isSaved: json['isSaved'] as bool,
    isPaused: json['isPaused'] as bool,
  );
}
