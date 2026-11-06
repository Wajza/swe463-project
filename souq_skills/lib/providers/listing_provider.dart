import 'package:flutter/foundation.dart';

import '../data/demo_listings.dart';
import '../models/skill_listing.dart';
import '../models/user_profile.dart';

class ListingProvider extends ChangeNotifier {
  // Temporary frontend state; replace with repository integration later.
  final List<SkillListing> _listings = [...demoListings];
  int _sequence = 0;

  List<SkillListing> get listings => List.unmodifiable(_listings);

  List<SkillListing> ownedBy(String userId) {
    return List.unmodifiable(
      _listings.where((listing) => listing.ownerId == userId),
    );
  }

  SkillListing publish({
    required UserProfile owner,
    required String offered,
    required String wanted,
    required String category,
    required String description,
    required String location,
    required String availability,
    required bool onlineOnly,
    required bool womenOnly,
  }) {
    if (offered.trim().isEmpty ||
        wanted.trim().isEmpty ||
        category.trim().isEmpty ||
        description.trim().isEmpty ||
        availability.trim().isEmpty ||
        (!onlineOnly && location.trim().isEmpty)) {
      throw ArgumentError('Please complete the required listing details.');
    }

    final listing = SkillListing(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}',
      ownerId: owner.id,
      title: offered.trim(),
      owner: owner.shownName,
      category: category.trim(),
      offers: offered.trim(),
      wants: wanted.trim(),
      distance: '',
      rating: 0,
      description: description.trim(),
      location: onlineOnly ? '' : location.trim(),
      availability: availability.trim(),
      onlineOnly: onlineOnly,
      womenOnly: womenOnly,
      isVerified: owner.phoneVerified,
    );

    _listings.insert(0, listing);
    notifyListeners();
    return listing;
  }
}
