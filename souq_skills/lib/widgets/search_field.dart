import 'package:flutter/material.dart';

/// Filters results as the member types, with a filter button built in.
class SearchField extends StatelessWidget {
  const SearchField({
    required this.onChanged,
    required this.onFilterTap,
    required this.activeFilterCount,
    super.key,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) => TextField(
    textInputAction: TextInputAction.search,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: 'Search for a skill',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: IconButton(
        tooltip: 'Filter',
        onPressed: onFilterTap,
        icon: Badge(
          isLabelVisible: activeFilterCount > 0,
          label: Text('$activeFilterCount'),
          child: const Icon(Icons.tune),
        ),
      ),
    ),
  );
}
