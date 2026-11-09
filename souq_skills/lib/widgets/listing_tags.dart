import 'package:flutter/material.dart';
import 'package:souq_skills/models/skill_listing.dart';

import 'status_chip.dart';

class ListingTags extends StatelessWidget {
  const ListingTags({required this.listing, super.key});

  final SkillListing listing;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      for (final tag in listing.tags)
        StatusChip(label: tag.label, tone: StatusTone.neutral),
    ],
  );
}
