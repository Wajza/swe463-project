import '../models/skill_listing.dart';
import 'repository.dart';

class ListingService {
  ListingService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  Future<List<SkillListing>> getListings({String query = '', String? category, String? city, bool onlineOnly = false}) async {
    final normalized = query.trim().toLowerCase();
    return _repository.listings.where((item) {
      final searchable = '${item.title} ${item.offers} ${item.wants}'.toLowerCase();
      final matchesQuery = normalized.isEmpty || searchable.contains(normalized);
      final matchesCategory = category == null || item.category == category;
      final matchesCity = city == null || item.city == city;
      return matchesQuery && matchesCategory && matchesCity && (!onlineOnly || item.onlineOnly);
    }).toList();
  }
  Future<void> saveListing(String id) async {
    final index = _repository.listings.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _repository.listings[index] = _repository.listings[index].copyWith(
      isSaved: !_repository.listings[index].isSaved,
    );
    _repository.emitChange();
  }

  Future<SkillListing> createListing(SkillListing listing) async {
    _repository.listings.add(listing);
    _repository.emitChange();
    return listing;
  }

  Future<SkillListing?> updateListing(SkillListing listing) async {
    final index = _repository.listings.indexWhere((item) => item.id == listing.id);
    if (index < 0) return null;
    _repository.listings[index] = listing;
    _repository.emitChange();
    return listing;
  }

  Future<void> deleteListing(String id) async {
    _repository.listings.removeWhere((item) => item.id == id);
    _repository.emitChange();
  }

  Future<void> setListingPaused(String id, bool paused) async {
    final index = _repository.listings.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _repository.listings[index] = _repository.listings[index].copyWith(isPaused: paused);
    _repository.emitChange();
  }
}
