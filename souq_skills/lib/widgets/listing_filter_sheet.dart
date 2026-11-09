import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/category_config.dart';
import 'package:souq_skills/models/search_criteria.dart';

import 'choice_chip_row.dart';
import 'form_section.dart';
import 'listing_tag_selector.dart';

/// Filters that apply the moment they are tapped, with nothing to confirm.
class ListingFilterSheet extends StatefulWidget {
  const ListingFilterSheet({
    required this.initial,
    required this.onChanged,
    super.key,
  });

  final SearchCriteria initial;
  final ValueChanged<SearchCriteria> onChanged;

  static Future<void> show(
    BuildContext context, {
    required SearchCriteria initial,
    required ValueChanged<SearchCriteria> onChanged,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ListingFilterSheet(initial: initial, onChanged: onChanged),
  );

  @override
  State<ListingFilterSheet> createState() => _ListingFilterSheetState();
}

class _ListingFilterSheetState extends State<ListingFilterSheet> {
  late SearchCriteria _criteria = widget.initial;

  void _update(SearchCriteria criteria) {
    setState(() => _criteria = criteria);
    widget.onChanged(criteria);
  }

  Widget _buildOptional(
    List<String> options,
    String? selected,
    ValueChanged<String?> onSelected,
  ) => ChoiceChipRow<String?>(
    options: [null, ...options],
    selected: selected,
    labelOf: (option) => option ?? 'All',
    onSelected: onSelected,
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormSection(
            title: 'Category',
            child: _buildOptional(
              CategoryConfig.names,
              _criteria.category,
              (value) => _update(
                _criteria.copyWith(
                  category: value,
                  clearCategory: value == null,
                ),
              ),
            ),
          ),
          FormSection(
            title: 'City',
            child: _buildOptional(
              AppOptions.cities,
              _criteria.city,
              (value) => _update(
                _criteria.copyWith(city: value, clearCity: value == null),
              ),
            ),
          ),
          FormSection(
            title: 'Tags',
            child: ListingTagSelector(
              onlineOnly: _criteria.onlineOnly,
              womenOnly: _criteria.womenOnly,
              onChanged: (online, women) => _update(
                _criteria.copyWith(onlineOnly: online, womenOnly: women),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
