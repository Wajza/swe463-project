import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/listing_kind.dart';
import 'package:souq_skills/models/skill_post.dart';
import 'package:souq_skills/services/posting_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/skill_post_form.dart';

/// Posts a solo listing or a group trade from a single page of selections.
class PostSkillScreen extends StatelessWidget {
  const PostSkillScreen({this.initialKind = ListingKind.solo, super.key});

  final ListingKind initialKind;

  void _publish(BuildContext context, SkillPost post) {
    final id = PostingService().publish(post);
    context.resetThenOpen(
      post.isGroup ? AppRoutes.groupTradeDetails : AppRoutes.listingDetails,
      args: id,
    );
    context.showMessage(post.isGroup ? 'Group created' : 'Published');
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Post a skill',
    children: [
      SkillPostForm(
        initial: PostingService().draft(initialKind),
        canChangeKind: true,
        submitLabel: 'Publish',
        onSubmit: (post) => _publish(context, post),
      ),
    ],
  );
}
