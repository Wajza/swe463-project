import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/posting_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';
import 'package:souq_skills/widgets/overflow_menu.dart';
import 'package:souq_skills/widgets/skill_post_form.dart';

class EditListingScreen extends StatelessWidget {
  const EditListingScreen({required this.listingId, super.key});

  final String listingId;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Delete listing?',
      message: 'This removes the listing for everyone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    context
      ..back()
      ..back();
    ListingService().delete(listingId);
  }

  @override
  Widget build(BuildContext context) => LiveEntity<SkillListing>(
    find: () => ListingService().byId(listingId),
    builder: (context, listing) => AppPage(
      title: 'Edit listing',
      actions: [
        OverflowMenu(
          items: [
            MenuAction(
              listing.isPaused ? 'Resume listing' : 'Pause listing',
              () => ListingService().setPaused(listingId, !listing.isPaused),
            ),
            MenuAction('Delete listing', () => _delete(context)),
          ],
        ),
      ],
      children: [
        SkillPostForm(
          initial: PostingService().fromListing(listing),
          submitLabel: 'Save changes',
          onSubmit: (post) {
            PostingService().updateListing(listing, post);
            context.back();
            context.showMessage('Listing updated');
          },
        ),
      ],
    ),
  );
}
