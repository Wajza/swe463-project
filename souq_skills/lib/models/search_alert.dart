class SearchAlert {
  const SearchAlert({
    required this.name,
    required this.search,
    this.id = '',
    this.isEnabled = true,
  });

  final String id;
  final String name;
  final String search;
  final bool isEnabled;
}
