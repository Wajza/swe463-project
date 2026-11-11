import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/skill_listing.dart';
import 'package:souq_skills/models/skill_post.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/posting_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';
import 'package:souq_skills/widgets/overflow_menu.dart';
import 'package:souq_skills/widgets/skill_post_form.dart';
import 'package:souq_skills/widgets/status_page.dart';

class EditListingScreen extends StatefulWidget {
  const EditListingScreen({required this.listingId, super.key});

  final String listingId;

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  /// True while pausing, resuming or deleting, so only one runs at a time.
  bool _busy = false;

  /// Runs [action], reporting a failure and leaving everything as it was.
  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      return true;
    } on ListingException catch (error) {
      if (mounted) context.showMessage(error.message);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setPaused(SkillListing listing) async {
    final pausing = !listing.isPaused;
    final done = await _run(
      () => ListingService().setPaused(widget.listingId, pausing),
    );
    if (done && mounted) {
      context.showMessage(pausing ? 'Listing paused' : 'Listing resumed');
    }
  }

  /// Leaves the screen only once the listing has been deleted.
  Future<void> _delete() async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Delete listing?',
      message: 'This removes the listing for everyone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final deleted = await _run(() => ListingService().delete(widget.listingId));
    if (!deleted || !mounted) return;
    context
      ..back()
      ..back()
      ..showMessage('Listing deleted');
  }

  Future<void> _save(SkillListing listing, SkillPost post) async {
    try {
      await PostingService().updateListing(listing, post);
    } on ListingException catch (error) {
      if (mounted) context.showMessage(error.message);
      return;
    }
    if (!mounted) return;
    context.back();
    context.showMessage('Listing updated');
  }

  @override
  Widget build(BuildContext context) => LiveEntity<SkillListing>(
    find: () => ListingService().byId(widget.listingId),
    builder: (context, listing) {
      if (!ListingService().isMine(listing)) {
        return StatusPage(
          icon: Icons.lock_outline,
          title: 'Not your listing',
          message: ListingException.notYours.message,
        );
      }
      return AppPage(
        title: 'Edit listing',
        actions: [
          if (!_busy)
            OverflowMenu(
              items: [
                MenuAction(
                  listing.isPaused ? 'Resume listing' : 'Pause listing',
                  () => _setPaused(listing),
                ),
                MenuAction('Delete listing', _delete),
              ],
            ),
        ],
        children: [
          if (_busy) const LinearProgressIndicator(),
          SkillPostForm(
            initial: PostingService().fromListing(listing),
            submitLabel: 'Save changes',
            onSubmit: (post) => _save(listing, post),
          ),
        ],
      );
    },
  );
}
