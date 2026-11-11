import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/posting_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/skill_post_form.dart';

class EditGroupTradeScreen extends StatelessWidget {
  const EditGroupTradeScreen({required this.groupId, super.key});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final group = GroupTradeService().byId(groupId);
    if (group == null) return const NotFoundScreen();
    return AppPage(
      title: 'Edit group trade',
      children: [
        SkillPostForm(
          initial: PostingService().fromGroup(group),
          submitLabel: 'Save changes',
          onSubmit: (post) async {
            try {
              await PostingService().updateGroup(group, post);
            } on GroupTradeException catch (error) {
              if (context.mounted) context.showMessage(error.message);
              return;
            }
            if (!context.mounted) return;
            context.back();
            context.showMessage('Group trade updated');
          },
        ),
      ],
    );
  }
}
