import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class GroupTradeInvitationScreen extends StatelessWidget {
  const GroupTradeInvitationScreen({required this.groupId, super.key});

  final String groupId;

  void _accept(BuildContext context) {
    GroupTradeService().join(groupId);
    context.replaceWith(AppRoutes.groupTradeDetails, args: groupId);
  }

  void _decline(BuildContext context) {
    GroupTradeService().declineInvitation(groupId);
    context.back();
  }

  @override
  Widget build(BuildContext context) => LiveEntity<GroupTrade>(
    find: () => GroupTradeService().byId(groupId),
    builder: (context, group) {
      if (!GroupTradeService().isInvited(group)) {
        return StatusPage(
          pageTitle: 'Group invitation',
          icon: Icons.mail_outline,
          title: 'No open invitation',
          message: 'This invitation has already been answered.',
          actions: [
            SouqButton(
              label: 'View group',
              onPressed: () => context.replaceWith(
                AppRoutes.groupTradeDetails,
                args: groupId,
              ),
            ),
          ],
        );
      }
      return StatusPage(
        pageTitle: 'Group invitation',
        icon: Icons.mail_outline,
        title: group.title,
        message:
            '${MemberService().nameOf(group.ownerId)} invited you to join.\n\n'
            '${group.description}',
        actions: [
          SouqButton(
            label: 'Accept invitation',
            onPressed: () => _accept(context),
          ),
          SouqButton(
            label: 'Decline',
            outlined: true,
            onPressed: () => _decline(context),
          ),
        ],
      );
    },
  );
}
