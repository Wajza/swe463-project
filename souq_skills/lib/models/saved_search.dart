import 'identifiable.dart';

class SavedSearch implements Identifiable {
  const SavedSearch({
    this.id = '',
    this.query = '',
    this.category,
    this.city,
    this.onlineOnly = false,
    this.womenOnly = false,
  });

  @override
  final String id;
  final String query;
  final String? category;
  final String? city;
  final bool onlineOnly;
  final bool womenOnly;

  bool get hasCriteria =>
      query.trim().isNotEmpty ||
      category != null ||
      city != null ||
      onlineOnly ||
      womenOnly;

  String get summary {
    final parts = [
      if (query.trim().isNotEmpty) '"${query.trim()}"',
      ?category,
      ?city,
      if (onlineOnly) 'Online',
      if (womenOnly) 'Women only',
    ];
    return parts.isEmpty ? 'All skills' : parts.join(' • ');
  }

  SavedSearch copyWith({
    String? id,
    String? query,
    String? category,
    String? city,
    bool? onlineOnly,
    bool? womenOnly,
    bool clearCategory = false,
    bool clearCity = false,
  }) => SavedSearch(
    id: id ?? this.id,
    query: query ?? this.query,
    category: clearCategory ? null : category ?? this.category,
    city: clearCity ? null : city ?? this.city,
    onlineOnly: onlineOnly ?? this.onlineOnly,
    womenOnly: womenOnly ?? this.womenOnly,
  );
}
