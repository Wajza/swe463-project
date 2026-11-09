import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/invite_member_sheet.dart';
import 'package:souq_skills/widgets/member_tile.dart';
import 'package:souq_skills/widgets/overflow_menu.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/skill_chips.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_chip.dart';

import 'delete_group_trade_dialog.dart';

class GroupTradeDetailsScreen extends StatelessWidget {
  const GroupTradeDetailsScreen({required this.groupId, super.key});

  final String groupId;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await DeleteGroupTradeDialog.confirm(context);
    if (!confirmed || !context.mounted) return;
    context.back();
    GroupTradeService().delete(groupId);
  }

  void _complete(BuildContext context) {
    GroupTradeService().complete(groupId);
    context.replaceWith(AppRoutes.rateTrade, args: groupId);
  }

  void _declineInvitation(BuildContext context) {
    context.back();
    GroupTradeService().declineInvitation(groupId);
  }

  void _leave(BuildContext context) {
    context.back();
    GroupTradeService().leave(groupId);
  }

  /// The one next step for this member and this group's current status.
  Widget? _nextStep(BuildContext context, GroupTrade group) {
    final service = GroupTradeService();
    if (service.isInvited(group)) {
      return SouqButton(
        label: 'Accept invitation',
        onPressed: () => service.acceptInvitation(groupId),
      );
    }
    if (!service.isMember(group)) return null;
    if (group.isCompleted && !ReviewService().hasRated(groupId)) {
      return SouqButton(
        label: 'Rate this experience',
        icon: Icons.star_outline,
        onPressed: () => context.open(AppRoutes.rateTrade, args: groupId),
      );
    }
    if (service.canComplete(group)) {
      return SouqButton(
        label: 'Mark as complete',
        icon: Icons.task_alt,
        onPressed: () => _complete(context),
      );
    }
    return null;
  }

  List<MenuAction> _menu(BuildContext context, GroupTrade group) {
    final service = GroupTradeService();
    return [
      if (service.isInvited(group))
        MenuAction('Decline invitation', () => _declineInvitation(context)),
      if (service.isOwner(group)) ...[
        MenuAction(
          'Edit group',
          () => context.open(AppRoutes.editGroupTrade, args: groupId),
        ),
        MenuAction('Delete group', () => _delete(context)),
      ] else if (service.isMember(group) && !group.isCompleted)
        MenuAction('Leave group', () => _leave(context)),
    ];
  }

  @override
  Widget build(BuildContext context) => LiveEntity<GroupTrade>(
    find: () => GroupTradeService().byId(groupId),
    builder: (context, group) {
      final service = GroupTradeService();
      final menu = _menu(context, group);
      final canInvite = service.isOwner(group) && !group.isCompleted;
      return AppPage(
        title: group.title,
        actions: [
          if (service.isMember(group))
            IconButton(
              tooltip: 'Open group chat',
              onPressed: () => context.open(AppRoutes.groupChat, args: groupId),
              icon: const Icon(Icons.chat_outlined),
            ),
          if (menu.isNotEmpty) OverflowMenu(items: menu),
        ],
        action: _nextStep(context, group),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip.group(group.status),
          ),
          const SizedBox(height: 12),
          Text(group.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 6),
          Text('Invite only • ${group.sessionsMinutes}-minute sessions'),
          const SectionHeader(title: 'Skills'),
          SkillChips(skills: group.skills),
          SectionHeader(
            title: 'Members (${group.memberIds.length})',
            actionLabel: canInvite ? 'Invite' : null,
            onAction: () => InviteMemberSheet.show(context, group),
          ),
          for (final memberId in group.memberIds)
            MemberTile(
              memberId: memberId,
              caption: memberId == group.ownerId ? 'Organizer' : null,
            ),
          for (final memberId in group.invitedIds)
            MemberTile(memberId: memberId, caption: 'Invited'),
        ],
      );
    },
  );
}
