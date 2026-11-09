/// What the member is currently searching and filtering for on Home.
class SearchCriteria {
  const SearchCriteria({
    this.query = '',
    this.category,
    this.city,
    this.onlineOnly = false,
    this.womenOnly = false,
  });

  final String query;
  final String? category;
  final String? city;
  final bool onlineOnly;
  final bool womenOnly;

  int get activeFilterCount => [
    category != null,
    city != null,
    onlineOnly,
    womenOnly,
  ].where((isActive) => isActive).length;

  SearchCriteria copyWith({
    String? query,
    String? category,
    String? city,
    bool? onlineOnly,
    bool? womenOnly,
    bool clearCategory = false,
    bool clearCity = false,
  }) => SearchCriteria(
    query: query ?? this.query,
    category: clearCategory ? null : category ?? this.category,
    city: clearCity ? null : city ?? this.city,
    onlineOnly: onlineOnly ?? this.onlineOnly,
    womenOnly: womenOnly ?? this.womenOnly,
  );
}
