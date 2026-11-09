import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/safety_service.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class BlockMemberScreen extends StatelessWidget {
  const BlockMemberScreen({required this.memberId, super.key});

  final String memberId;

  void _block(BuildContext context, String name) {
    SafetyService().blockMember(memberId);
    context.resetTo(AppRoutes.home);
    context.showMessage('$name was blocked');
  }

  @override
  Widget build(BuildContext context) {
    final name = MemberService().nameOf(memberId);
    return StatusPage(
      pageTitle: 'Block member',
      icon: Icons.block,
      title: 'Block $name?',
      message:
          'You will no longer see their listings or chats. '
          'You can unblock them in Settings.',
      actions: [
        SouqButton(
          label: 'Block',
          destructive: true,
          onPressed: () => _block(context, name),
        ),
        SouqButton(
          label: 'Cancel',
          outlined: true,
          onPressed: () => context.back(),
        ),
      ],
    );
  }
}
