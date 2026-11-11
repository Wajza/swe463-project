import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/services/listing_service.dart';

/// The heart that saves a listing for the signed-in member, or unsaves it.
class SaveListingButton extends StatelessWidget {
  const SaveListingButton({required this.listing, this.color, super.key});

  final SkillListing listing;
  final Color? color;

  Future<void> _toggle(BuildContext context) async {
    try {
      await ListingService().toggleSaved(listing.id);
    } on ListingException catch (error) {
      if (context.mounted) context.showMessage(error.message);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<String>>(
    valueListenable: ListingService.savingIds,
    builder: (context, saving, _) => IconButton(
      tooltip: listing.isSaved ? 'Remove from saved' : 'Save skill',
      // While the change is being saved, further taps are ignored. The
      // button stays enabled so it still takes the tap, rather than letting
      // it through to the card underneath, which would open the listing.
      onPressed: saving.contains(listing.id) ? () {} : () => _toggle(context),
      icon: Icon(
        listing.isSaved ? Icons.favorite : Icons.favorite_border,
        color: color,
      ),
    ),
  );
}
