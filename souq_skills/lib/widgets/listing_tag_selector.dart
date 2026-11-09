import 'package:flutter/material.dart';
import 'package:souq_skills/models/listing_tag.dart';

import 'multi_choice_chip_row.dart';

/// Chooses tags, both when posting a listing and when filtering listings.
class ListingTagSelector extends StatelessWidget {
  const ListingTagSelector({
    required this.onlineOnly,
    required this.womenOnly,
    required this.onChanged,
    super.key,
  });

  final bool onlineOnly;
  final bool womenOnly;
  final void Function(bool onlineOnly, bool womenOnly) onChanged;

  @override
  Widget build(BuildContext context) => MultiChoiceChipRow(
    options: [for (final tag in ListingTag.values) tag.label],
    selected: [
      if (onlineOnly) ListingTag.onlineOnly.label,
      if (womenOnly) ListingTag.womenOnly.label,
    ],
    onChanged: (selected) => onChanged(
      selected.contains(ListingTag.onlineOnly.label),
      selected.contains(ListingTag.womenOnly.label),
    ),
  );
}
