import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/member_tile.dart';
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

  List<Widget> _actions(BuildContext context, GroupTrade group) {
    final service = GroupTradeService();
    if (service.isInvited(group)) {
      return [
        SouqButton(
          label: 'View invitation',
          onPressed: () =>
              context.open(AppRoutes.groupTradeInvitation, args: groupId),
        ),
      ];
    }
    if (!service.isMember(group)) {
      if (group.isCompleted) return const [];
      return [
        SouqButton(label: 'Join group', onPressed: () => service.join(groupId)),
      ];
    }
    return [
      SouqButton(
        label: 'Open group chat',
        icon: Icons.chat_outlined,
        onPressed: () => context.open(AppRoutes.groupChat, args: groupId),
      ),
      if (group.isCompleted && !ReviewService().hasRated(groupId))
        SouqButton(
          label: 'Rate this experience',
          outlined: true,
          icon: Icons.star_outline,
          onPressed: () => context.open(AppRoutes.rateTrade, args: groupId),
        ),
      if (service.canComplete(group))
        SouqButton(
          label: 'Mark as complete',
          outlined: true,
          icon: Icons.task_alt,
          onPressed: () =>
              context.open(AppRoutes.groupTradeCompletion, args: groupId),
        ),
      if (!service.isOwner(group) && !group.isCompleted)
        SouqButton(
          label: 'Leave group',
          outlined: true,
          destructive: true,
          onPressed: () => service.leave(groupId),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) => LiveEntity<GroupTrade>(
    find: () => GroupTradeService().byId(groupId),
    builder: (context, group) => AppPage(
      title: group.title,
      actions: [
        if (GroupTradeService().isOwner(group)) ...[
          IconButton(
            tooltip: 'Edit',
            onPressed: () =>
                context.open(AppRoutes.editGroupTrade, args: groupId),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ],
      footer: _actions(context, group),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StatusChip.group(group.status),
        ),
        const SizedBox(height: 12),
        Text(group.description, style: const TextStyle(height: 1.5)),
        const SizedBox(height: 6),
        Text('${group.sessionsMinutes}-minute sessions'),
        const SectionHeader(title: 'Skills'),
        SkillChips(skills: group.skills),
        SectionHeader(title: 'Members (${group.memberIds.length})'),
        for (final memberId in group.memberIds)
          MemberTile(
            memberId: memberId,
            caption: memberId == group.ownerId ? 'Organizer' : null,
          ),
      ],
    ),
  );
}
