import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/screens/shared/live_entity.dart';
import 'package:souq_skills/services/group_trade_service.dart';
import 'package:souq_skills/services/member_service.dart';
import 'package:souq_skills/services/review_service.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/confirmation_dialog.dart';
import 'package:souq_skills/widgets/invite_member_sheet.dart';
import 'package:souq_skills/widgets/member_tile.dart';
import 'package:souq_skills/widgets/overflow_menu.dart';
import 'package:souq_skills/widgets/section_header.dart';
import 'package:souq_skills/widgets/skill_chips.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_chip.dart';

import 'delete_group_trade_dialog.dart';

class GroupTradeDetailsScreen extends StatefulWidget {
  const GroupTradeDetailsScreen({required this.groupId, super.key});

  final String groupId;

  @override
  State<GroupTradeDetailsScreen> createState() =>
      _GroupTradeDetailsScreenState();
}

class _GroupTradeDetailsScreenState extends State<GroupTradeDetailsScreen> {
  /// True while a change to an online group is being saved.
  bool _busy = false;

  String get groupId => widget.groupId;

  /// Runs a group change, showing why it failed; returns whether it worked.
  /// Changes to groups on this device finish at once and never fail.
  Future<bool> _run(Future<void> Function() action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      return true;
    } on GroupTradeException catch (error) {
      if (mounted) context.showMessage(error.message);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await DeleteGroupTradeDialog.confirm(context);
    if (!confirmed || !mounted) return;
    if (await _run(() => GroupTradeService().deleteGroup(groupId)) && mounted) {
      context.back();
    }
  }

  Future<void> _complete(GroupTrade group) async {
    var completed = false;
    final saved = await _run(
      () async => completed = await GroupTradeService().complete(groupId),
    );
    if (!saved || !mounted) return;
    if (completed) {
      context.replaceWith(AppRoutes.rateTrade, args: groupId);
    } else {
      context.showMessage(_waitingMessage(group, afterConfirming: true));
    }
  }

  /// An online group completes once every member has confirmed.
  static String _waitingMessage(
    GroupTrade group, {
    bool afterConfirming = false,
  }) {
    final waiting =
        GroupTradeService().waitingFor(group) - (afterConfirming ? 1 : 0);
    return waiting == 1
        ? 'Waiting for 1 member to confirm'
        : 'Waiting for $waiting members to confirm';
  }

  Future<void> _declineInvitation() async {
    if (await _run(() => GroupTradeService().declineInvitation(groupId)) &&
        mounted) {
      context.back();
    }
  }

  Future<void> _leave() async {
    if (await _run(() => GroupTradeService().leave(groupId)) && mounted) {
      context.back();
    }
  }

  Future<void> _remove(String memberId) async {
    final confirmed = await ConfirmationDialog.confirm(
      context,
      title: 'Remove ${MemberService().nameOf(memberId)}?',
      message: 'They leave the group and its chat.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _run(() => GroupTradeService().removeMember(groupId, memberId));
  }

  /// The one next step for this member and this group's current status.
  Widget? _nextStep(GroupTrade group) {
    final service = GroupTradeService();
    if (service.isInvited(group)) {
      return SouqButton(
        label: _busy ? 'Joining…' : 'Accept invitation',
        onPressed: _busy
            ? null
            : () => _run(() => service.acceptInvitation(groupId)),
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
      final confirming =
          service.isOnline(group) && !service.hasConfirmed(group);
      return SouqButton(
        label: _busy
            ? 'Saving…'
            : confirming && group.confirmedIds.isNotEmpty
            ? 'Confirm completion'
            : 'Mark as complete',
        icon: Icons.task_alt,
        onPressed: _busy ? null : () => _complete(group),
      );
    }
    if (service.isOnline(group) &&
        service.hasConfirmed(group) &&
        !group.isCompleted) {
      return SouqButton(
        label: _waitingMessage(group),
        icon: Icons.hourglass_empty,
        onPressed: null,
      );
    }
    return null;
  }

  List<MenuAction> _menu(GroupTrade group) {
    final service = GroupTradeService();
    return [
      if (service.isInvited(group))
        MenuAction('Decline invitation', _declineInvitation),
      if (service.isOwner(group)) ...[
        // A completed online group is final.
        if (!service.isOnline(group) || !group.isCompleted)
          MenuAction(
            'Edit group',
            () => context.open(AppRoutes.editGroupTrade, args: groupId),
          ),
        if (service.canDelete(group)) MenuAction('Delete group', _delete),
      ] else if (service.isMember(group) && !group.isCompleted)
        MenuAction('Leave group', _leave),
    ];
  }

  /// What the member list says about [memberId].
  static String? _captionOf(GroupTrade group, String memberId) {
    final service = GroupTradeService();
    final confirmed =
        service.isOnline(group) &&
        !group.isCompleted &&
        group.confirmedIds.contains(memberId);
    return switch ((memberId == group.ownerId, confirmed)) {
      (true, true) => 'Organizer • Confirmed',
      (true, false) => 'Organizer',
      (false, true) => 'Confirmed',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) => LiveEntity<GroupTrade>(
    find: () => GroupTradeService().byId(groupId),
    builder: (context, group) {
      final service = GroupTradeService();
      final menu = _menu(group);
      final canInvite =
          service.isOwner(group) &&
          !group.isCompleted &&
          group.status != GroupTradeStatus.cancelled;
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
        action: _nextStep(group),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: StatusChip.group(group.status),
          ),
          const SizedBox(height: 12),
          Text(group.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 6),
          Text('Invite only • ${group.sessionsMinutes}-minute sessions'),
          if (service.isOnline(group) &&
              !group.isCompleted &&
              group.memberIds.length >= 2) ...[
            const SizedBox(height: 6),
            Text(
              'Completes when every member confirms '
              '(${group.memberIds.length - service.waitingFor(group)} of '
              '${group.memberIds.length} so far). Each member then gets '
              '${GroupTradeService.completionCredits} credits.',
            ),
          ],
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
              caption: _captionOf(group, memberId),
              trailing: service.canRemove(group, memberId)
                  ? IconButton(
                      tooltip: 'Remove from group',
                      onPressed: _busy ? null : () => _remove(memberId),
                      icon: const Icon(Icons.person_remove_outlined),
                    )
                  : null,
            ),
          for (final memberId in group.invitedIds)
            MemberTile(memberId: memberId, caption: 'Invited'),
        ],
      );
    },
  );
}
