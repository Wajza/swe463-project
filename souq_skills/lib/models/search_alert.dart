import 'identifiable.dart';
import 'saved_search.dart';

class SearchAlert implements Identifiable {
  const SearchAlert({
    required this.id,
    required this.criteria,
    this.isEnabled = true,
  });

  @override
  final String id;
  final SavedSearch criteria;
  final bool isEnabled;

  SearchAlert copyWith({bool? isEnabled}) => SearchAlert(
    id: id,
    criteria: criteria,
    isEnabled: isEnabled ?? this.isEnabled,
  );
}
