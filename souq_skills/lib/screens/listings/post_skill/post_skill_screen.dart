import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/listing_kind.dart';
import 'package:souq_skills/models/skill_post.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/posting_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/skill_post_form.dart';

/// Posts a solo listing or a group trade from a single page of selections.
class PostSkillScreen extends StatelessWidget {
  const PostSkillScreen({this.initialKind = ListingKind.solo, super.key});

  final ListingKind initialKind;

  /// Only leaves the page once the listing or group has been published.
  Future<void> _publish(BuildContext context, SkillPost post) async {
    final String id;
    try {
      id = await PostingService().publish(post);
    } on ListingException catch (error) {
      if (context.mounted) context.showMessage(error.message);
      return;
    } on GroupTradeException catch (error) {
      if (context.mounted) context.showMessage(error.message);
      return;
    }
    if (!context.mounted) return;
    if (post.isGroup) {
      context.resetThenOpen(AppRoutes.groupTradeDetails, args: id);
      context.showMessage('Group created');
    } else {
      // The success page says it was published and links to the listing.
      context.resetThenOpen(AppRoutes.listingPublished, args: id);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Post a skill',
    children: [
      SkillPostForm(
        initial: PostingService().draft(initialKind),
        canChangeKind: true,
        submitLabel: 'Publish',
        busyLabel: 'Publishing…',
        onSubmit: (post) => _publish(context, post),
      ),
    ],
  );
}
