import 'package:flutter/material.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/models/group_trade.dart';
import 'package:souq_skills/models/user.dart';
import 'package:souq_skills/services/group_trade_service.dart';

import 'user_avatar.dart';

/// Finds a member by username and invites them to a group.
class InviteMemberSheet extends StatefulWidget {
  const InviteMemberSheet({required this.group, super.key});

  final GroupTrade group;

  static Future<void> show(BuildContext context, GroupTrade group) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => InviteMemberSheet(group: group),
      );

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
  String _query = '';

  void _invite(User member) {
    GroupTradeService().invite(widget.group.id, member);
    Navigator.pop(context);
    context.showMessage('Invitation sent to @${member.username}');
  }

  @override
  Widget build(BuildContext context) {
    final matches = GroupTradeService().inviteCandidates(widget.group, _query);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixText: '@',
              ),
            ),
            if (_query.trim().isNotEmpty && matches.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('No member can be invited with that username.'),
              ),
            for (final member in matches)
              ListTile(
                leading: UserAvatar(initials: member.initials),
                title: Text('@${member.username}'),
                subtitle: Text(member.name),
                trailing: const Icon(Icons.person_add_alt),
                onTap: () => _invite(member),
              ),
          ],
        ),
      ),
    );
  }
}
