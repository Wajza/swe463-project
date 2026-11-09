import 'package:souq_skills/models/saved_search.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/user.dart';

import 'badge_service.dart';
import 'repository.dart';

class ListingService {
  final Repository _repo = Repository.instance;

  /// Active listings from other, unblocked members that match [criteria].
  List<SkillListing> discover(SavedSearch criteria) {
    final query = criteria.query.trim().toLowerCase();
    return _repo.listings.where((item) {
      final text = '${item.title} ${item.offers} ${item.wants}'.toLowerCase();
      return item.ownerId != User.currentUserId &&
          !item.isPaused &&
          !_repo.blockedMemberIds.contains(item.ownerId) &&
          (query.isEmpty || text.contains(query)) &&
          (criteria.category == null || item.category == criteria.category) &&
          (criteria.city == null || item.city == criteria.city) &&
          (!criteria.onlineOnly || item.onlineOnly) &&
          (!criteria.womenOnly || item.womenOnly);
    }).toList();
  }

  SkillListing? byId(String id) => _repo.find(_repo.listings, id);

  List<SkillListing> byOwner(String ownerId) =>
      _repo.listings.where((item) => item.ownerId == ownerId).toList();

  List<SkillListing> activeByOwner(String ownerId) =>
      byOwner(ownerId).where((item) => !item.isPaused).toList();

  List<SkillListing> mine() => byOwner(User.currentUserId);

  List<SkillListing> saved() =>
      _repo.listings.where((item) => item.isSaved).toList();

  bool isMine(SkillListing listing) => listing.ownerId == User.currentUserId;

  SkillListing create(SkillListing draft) {
    final listing = draft.copyWith(id: _repo.nextId('l'));
    _repo.insert(_repo.listings, listing);
    BadgeService().sync();
    return listing;
  }

  void update(SkillListing listing) =>
      _repo.update(_repo.listings, listing.id, (_) => listing);

  void delete(String id) => _repo.remove(_repo.listings, id);

  void toggleSaved(String id) => _repo.update(
    _repo.listings,
    id,
    (item) => item.copyWith(isSaved: !item.isSaved),
  );

  void setPaused(String id, bool paused) => _repo.update(
    _repo.listings,
    id,
    (item) => item.copyWith(isPaused: paused),
  );
}
