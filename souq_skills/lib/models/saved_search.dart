class SavedSearch {
  const SavedSearch({
    required this.query,
    this.id = '',
    this.category,
    this.city,
    this.onlineOnly = false,
    this.womenOnly = false,
  });

  final String id;
  final String query;
  final String? category;
  final String? city;
  final bool onlineOnly;
  final bool womenOnly;
}
