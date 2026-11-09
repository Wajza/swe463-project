import 'package:souq_skills/models/saved_search.dart';
import 'package:souq_skills/models/search_alert.dart';

import 'repository.dart';

class SearchService {
  final Repository _repo = Repository.instance;

  List<SavedSearch> savedSearches() => _repo.savedSearches.toList();

  List<SearchAlert> alerts() => _repo.searchAlerts.toList();

  void saveSearch(SavedSearch criteria) => _repo.insert(
    _repo.savedSearches,
    criteria.copyWith(id: _repo.nextId('ss')),
  );

  void deleteSearch(String id) => _repo.remove(_repo.savedSearches, id);

  void createAlert(SavedSearch criteria) => _repo.insert(
    _repo.searchAlerts,
    SearchAlert(id: _repo.nextId('sa'), criteria: criteria),
  );

  void setAlertEnabled(String id, bool enabled) => _repo.update(
    _repo.searchAlerts,
    id,
    (alert) => alert.copyWith(isEnabled: enabled),
  );

  void deleteAlert(String id) => _repo.remove(_repo.searchAlerts, id);
}
